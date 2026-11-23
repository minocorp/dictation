import Core

internal struct FrameAssembler {
    struct Frame: Equatable {
        let startSample: Int
        let samples: [Float]
    }

    private let frameSize: Int
    private var pending: [Float] = []
    private var pendingStart = 0
    private var nextExpected: Int?

    init(frameSize: Int) {
        self.frameSize = frameSize
    }

    mutating func append(_ chunk: AudioChunk) -> [Frame] {
        var frames: [Frame] = []
        if let nextExpected, nextExpected != chunk.startSample, let gap = flush() {
            frames.append(gap)
        }
        if pending.isEmpty { pendingStart = chunk.startSample }
        pending += chunk.samples
        nextExpected = chunk.startSample + chunk.samples.count
        while pending.count >= frameSize {
            frames.append(Frame(startSample: pendingStart, samples: Array(pending[..<frameSize])))
            pending.removeFirst(frameSize)
            pendingStart += frameSize
        }
        return frames
    }

    mutating func flush() -> Frame? {
        guard !pending.isEmpty else { return nil }
        defer {
            pendingStart += pending.count
            pending = []
        }
        return Frame(startSample: pendingStart, samples: pending)
    }
}
