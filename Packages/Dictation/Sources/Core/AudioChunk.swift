public struct AudioChunk: Hashable, Sendable {
    public static let sampleRate = 16_000

    public let samples: [Float]
    public let startSample: Int

    public init(samples: [Float], startSample: Int) {
        self.samples = samples
        self.startSample = startSample
    }
}
