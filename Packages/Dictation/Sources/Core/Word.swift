public struct Word: Hashable, Sendable {
    public enum Source: String, Hashable, Sendable {
        case manual
        case learned
    }

    public let text: String
    public let soundsLike: [String]
    public let source: Source

    public init(text: String, soundsLike: [String], source: Source) {
        self.text = text
        self.soundsLike = soundsLike
        self.source = source
    }
}
