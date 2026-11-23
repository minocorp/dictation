public struct AudioCapture: Sendable {
    public let chunks: AsyncStream<AudioChunk>
    public let failures: AsyncStream<CaptureError>

    public init(chunks: AsyncStream<AudioChunk>, failures: AsyncStream<CaptureError>) {
        self.chunks = chunks
        self.failures = failures
    }
}
