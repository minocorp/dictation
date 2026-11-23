import AudioToolbox

internal final class HALRenderContext {
    static let maximumFrames = 16_384

    let ring: SPSCRingBuffer

    private let unit: AudioUnit
    private let channelCount: Int
    private let scratch: UnsafeMutablePointer<Float>

    init(unit: AudioUnit, channelCount: Int, ring: SPSCRingBuffer) {
        self.unit = unit
        self.channelCount = channelCount
        self.ring = ring
        scratch = .allocate(capacity: Self.maximumFrames * channelCount)
        scratch.initialize(repeating: 0, count: Self.maximumFrames * channelCount)
    }

    deinit {
        scratch.deallocate()
    }

    func render(
        flags: UnsafeMutablePointer<AudioUnitRenderActionFlags>,
        timestamp: UnsafePointer<AudioTimeStamp>,
        bus: UInt32,
        frames: UInt32,
    ) -> OSStatus {
        guard Int(frames) <= Self.maximumFrames else { return noErr }
        let sampleCount = Int(frames) * channelCount
        var list = AudioBufferList(
            mNumberBuffers: 1,
            mBuffers: AudioBuffer(
                mNumberChannels: UInt32(channelCount),
                mDataByteSize: UInt32(sampleCount * MemoryLayout<Float>.size),
                mData: scratch,
            ),
        )
        let status = AudioUnitRender(unit, flags, timestamp, bus, frames, &list)
        guard status == noErr else { return status }
        _ = ring.write(
            UnsafeBufferPointer(start: scratch, count: sampleCount),
            frameSize: channelCount,
        )
        return noErr
    }
}
