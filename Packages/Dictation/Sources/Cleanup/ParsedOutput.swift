public struct ParsedOutput: Hashable, Sendable {
    public let text: String
    public let hasClosingTag: Bool

    public init(text: String, hasClosingTag: Bool) {
        self.text = text
        self.hasClosingTag = hasClosingTag
    }
}
