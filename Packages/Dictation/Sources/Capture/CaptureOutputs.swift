import Core

internal struct CaptureOutputs: Sendable {
    let chunks: AsyncStream<AudioChunk>.Continuation
    let failures: AsyncStream<CaptureError>.Continuation
}
