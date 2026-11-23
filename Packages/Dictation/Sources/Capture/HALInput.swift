import AudioToolbox
import Core

internal final class HALInput {
    private static let ringSeconds = 2
    private static let callback: AURenderCallback = { refCon, flags, timestamp, bus, frames, _ in
        Unmanaged<HALRenderContext>.fromOpaque(refCon)
            .takeUnretainedValue()
            .render(flags: flags, timestamp: timestamp, bus: bus, frames: frames)
    }

    let sampleRate: Double
    let channelCount: Int
    let ring: SPSCRingBuffer

    private let unit: AudioUnit
    private let context: HALRenderContext
    private var isDisposed = false

    private init(unit: AudioUnit, format: AudioStreamBasicDescription) {
        self.unit = unit
        sampleRate = format.mSampleRate
        channelCount = Int(format.mChannelsPerFrame)
        ring = SPSCRingBuffer(capacity: Int(format.mSampleRate) * channelCount * Self.ringSeconds)
        context = HALRenderContext(unit: unit, channelCount: channelCount, ring: ring)
    }

    deinit {
        dispose()
    }

    static func open(deviceID: UInt32) throws(CaptureError) -> HALInput {
        var description = AudioComponentDescription(
            componentType: kAudioUnitType_Output,
            componentSubType: kAudioUnitSubType_HALOutput,
            componentManufacturer: kAudioUnitManufacturer_Apple,
            componentFlags: 0,
            componentFlagsMask: 0,
        )
        guard let component = AudioComponentFindNext(nil, &description) else {
            throw .engineFailed(code: Int(kAudioUnitErr_InvalidProperty))
        }
        var created: AudioUnit?
        try AudioUnitProperty.check(AudioComponentInstanceNew(component, &created))
        guard let unit = created else {
            throw .engineFailed(code: Int(kAudioUnitErr_Uninitialized))
        }
        let format: AudioStreamBasicDescription
        do {
            format = try configure(unit, deviceID: deviceID)
        } catch {
            AudioComponentInstanceDispose(unit)
            throw error
        }
        let input = HALInput(unit: unit, format: format)
        do {
            try input.start()
        } catch {
            input.stop()
            throw error
        }
        return input
    }

    func stop() {
        dispose()
    }

    private static func configure(
        _ unit: AudioUnit,
        deviceID: UInt32,
    ) throws(CaptureError) -> AudioStreamBasicDescription {
        try AudioUnitProperty.enableInput.set(UInt32(1), on: unit)
        try AudioUnitProperty.disableOutput.set(UInt32(0), on: unit)
        try AudioUnitProperty.currentDevice.set(deviceID, on: unit)
        let hardware = try AudioUnitProperty.hardwareFormat.get(
            AudioStreamBasicDescription(),
            from: unit,
        )
        guard hardware.mSampleRate > 0, hardware.mChannelsPerFrame > 0 else {
            throw .deviceUnavailable
        }
        let client = clientFormat(matching: hardware)
        try AudioUnitProperty.clientFormat.set(client, on: unit)
        return client
    }

    private static func clientFormat(
        matching hardware: AudioStreamBasicDescription
    ) -> AudioStreamBasicDescription {
        let bytesPerFrame = UInt32(MemoryLayout<Float>.size) * hardware.mChannelsPerFrame
        return AudioStreamBasicDescription(
            mSampleRate: hardware.mSampleRate,
            mFormatID: kAudioFormatLinearPCM,
            mFormatFlags: kAudioFormatFlagsNativeFloatPacked,
            mBytesPerPacket: bytesPerFrame,
            mFramesPerPacket: 1,
            mBytesPerFrame: bytesPerFrame,
            mChannelsPerFrame: hardware.mChannelsPerFrame,
            mBitsPerChannel: UInt32(MemoryLayout<Float>.size * 8),
            mReserved: 0,
        )
    }

    private func start() throws(CaptureError) {
        let callback = AURenderCallbackStruct(
            inputProc: Self.callback,
            inputProcRefCon: Unmanaged.passUnretained(context).toOpaque(),
        )
        try AudioUnitProperty.inputCallback.set(callback, on: unit)
        try AudioUnitProperty.check(AudioUnitInitialize(unit))
        try AudioUnitProperty.check(AudioOutputUnitStart(unit))
    }

    private func dispose() {
        guard !isDisposed else { return }
        isDisposed = true
        AudioOutputUnitStop(unit)
        AudioUnitUninitialize(unit)
        AudioComponentInstanceDispose(unit)
    }
}
