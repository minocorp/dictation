public struct CleanupResult: Equatable, Sendable {
    public let text: String
    public let source: CleanupSource

    public init(text: String, source: CleanupSource) {
        self.text = text
        self.source = source
    }
}
