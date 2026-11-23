public import Core

public struct CleanupContext: Hashable, Sendable {
    public let dictionary: [Word]
    public let contextBefore: String
    public let isFinalSegment: Bool

    public init(dictionary: [Word], contextBefore: String, isFinalSegment: Bool) {
        self.dictionary = dictionary
        self.contextBefore = contextBefore
        self.isFinalSegment = isFinalSegment
    }
}
