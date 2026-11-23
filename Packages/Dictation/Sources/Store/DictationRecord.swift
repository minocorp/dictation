import Core
import Foundation
import GRDB

internal struct DictationRecord: Codable, FetchableRecord, PersistableRecord, Sendable {
    static let databaseTableName = "dictation"

    var id: String
    var createdAt: Date
    var appBundleID: String
    var appName: String
    var kind: String
    var rawText: String
    var finalText: String
    var instruction: String?
    var audioPath: String?
    var durationMs: Int
    var status: String

    init(_ item: HistoryItem, keepsAudio: Bool) {
        id = item.id.stem
        createdAt = item.date
        appBundleID = item.appBundleID
        appName = item.appName
        kind = item.kind.rawValue
        rawText = item.rawText
        finalText = item.finalText
        instruction = item.instruction
        audioPath = keepsAudio ? item.audioURL?.lastPathComponent : nil
        durationMs = Int((item.duration / .milliseconds(1)).rounded())
        status = item.status.rawValue
    }

    func item(audioDirectory: URL) throws(StoreError) -> HistoryItem {
        guard
            let dictationID = DictationID(stem: id),
            let kind = HistoryItem.Kind(rawValue: kind),
            let status = HistoryItem.Status(rawValue: status)
        else { throw .readFailed(code: 0) }
        return HistoryItem(
            id: dictationID,
            date: createdAt,
            appBundleID: appBundleID,
            appName: appName,
            kind: kind,
            rawText: rawText,
            finalText: finalText,
            instruction: instruction,
            audioURL: audioPath.map { audioDirectory.appending(path: $0) },
            duration: .milliseconds(durationMs),
            status: status,
        )
    }
}
