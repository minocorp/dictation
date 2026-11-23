public protocol VoiceActivity: Sendable {
    func segments(of chunks: AsyncStream<AudioChunk>, id: DictationID) -> AsyncStream<Segment>
}
