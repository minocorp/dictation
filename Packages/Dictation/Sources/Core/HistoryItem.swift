public import Foundation

public struct HistoryItem: Hashable, Sendable {
    public enum Kind: String, Hashable, Sendable {
        case dictation
        case edit
    }

    public enum Status: String, Hashable, Sendable {
        case inserted
        case copied
        case canceled
        case pending
        case recovered
        case failed
        case refused
    }

    public let id: DictationID
    public let date: Date
    public let appBundleID: String
    public let appName: String
    public let kind: Kind
    public let rawText: String
    public let finalText: String
    public let instruction: String?
    public let audioURL: URL?
    public let duration: Duration
    public let status: Status

    public init(
        id: DictationID,
        date: Date,
        appBundleID: String,
        appName: String,
        kind: Kind,
        rawText: String,
        finalText: String,
        instruction: String?,
        audioURL: URL?,
        duration: Duration,
        status: Status,
    ) {
        self.id = id
        self.date = date
        self.appBundleID = appBundleID
        self.appName = appName
        self.kind = kind
        self.rawText = rawText
        self.finalText = finalText
        self.instruction = instruction
        self.audioURL = audioURL
        self.duration = duration
        self.status = status
    }
}
