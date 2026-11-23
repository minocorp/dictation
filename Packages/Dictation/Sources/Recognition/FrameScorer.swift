internal struct FrameScorer: Sendable {
    let probability: @Sendable ([Float]) async -> Float
}
