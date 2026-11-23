public struct CleanInput: Equatable, Sendable {
    public let text: String
    public let contextBefore: String
    public let isFinalSegment: Bool

    public init(text: String, contextBefore: String, isFinalSegment: Bool) {
        self.text = text
        self.contextBefore = contextBefore
        self.isFinalSegment = isFinalSegment
    }
}
