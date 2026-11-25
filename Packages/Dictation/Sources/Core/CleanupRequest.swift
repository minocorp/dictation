public import Foundation

public struct CleanupRequest: Hashable, Sendable {
    public let text: String
    public let dictionary: [Word]
    public let contextBefore: String
    public let languages: [Locale]
    public let isFinalSegment: Bool

    public init(
        text: String,
        dictionary: [Word],
        contextBefore: String,
        languages: [Locale],
        isFinalSegment: Bool = true,
    ) {
        self.text = text
        self.dictionary = dictionary
        self.contextBefore = contextBefore
        self.languages = languages
        self.isFinalSegment = isFinalSegment
    }
}
