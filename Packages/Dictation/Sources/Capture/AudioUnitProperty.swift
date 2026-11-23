import AudioToolbox
import Core

internal struct AudioUnitProperty {
    static let enableInput = AudioUnitProperty(
        id: kAudioOutputUnitProperty_EnableIO,
        scope: kAudioUnitScope_Input,
        element: 1,
    )
    static let disableOutput = AudioUnitProperty(
        id: kAudioOutputUnitProperty_EnableIO,
        scope: kAudioUnitScope_Output,
        element: 0,
    )
    static let currentDevice = AudioUnitProperty(
        id: kAudioOutputUnitProperty_CurrentDevice,
        scope: kAudioUnitScope_Global,
        element: 0,
    )
    static let hardwareFormat = AudioUnitProperty(
        id: kAudioUnitProperty_StreamFormat,
        scope: kAudioUnitScope_Input,
        element: 1,
    )
    static let clientFormat = AudioUnitProperty(
        id: kAudioUnitProperty_StreamFormat,
        scope: kAudioUnitScope_Output,
        element: 1,
    )
    static let inputCallback = AudioUnitProperty(
        id: kAudioOutputUnitProperty_SetInputCallback,
        scope: kAudioUnitScope_Global,
        element: 0,
    )

    let id: AudioUnitPropertyID
    let scope: AudioUnitScope
    let element: AudioUnitElement

    static func check(_ status: OSStatus) throws(CaptureError) {
        guard status == noErr else { throw .engineFailed(code: Int(status)) }
    }

    func set<Value: BitwiseCopyable>(_ value: Value, on unit: AudioUnit) throws(CaptureError) {
        var copy = value
        let size = UInt32(MemoryLayout<Value>.size)
        try Self.check(AudioUnitSetProperty(unit, id, scope, element, &copy, size))
    }

    func get<Value: BitwiseCopyable>(
        _ initial: Value,
        from unit: AudioUnit,
    ) throws(CaptureError) -> Value {
        var value = initial
        var size = UInt32(MemoryLayout<Value>.size)
        try Self.check(AudioUnitGetProperty(unit, id, scope, element, &value, &size))
        return value
    }
}
