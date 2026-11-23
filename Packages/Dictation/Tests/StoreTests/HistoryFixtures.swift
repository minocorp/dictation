import Core
import Foundation
import Store

internal struct HistoryFixtures: Sendable {
    let directory = TestDirectory()

    var audioDirectory: URL { directory.url.appending(path: "Audio", directoryHint: .isDirectory) }

    func makeDatabase() throws(StoreError) -> HistoryDatabase {
        try HistoryDatabase(inMemoryWithAudioDirectory: audioDirectory)
    }

    func writeAudio(named stem: String) throws -> URL {
        let url = audioDirectory.appending(path: "\(stem).caf")
        try FileManager.default.createDirectory(
            at: audioDirectory,
            withIntermediateDirectories: true,
        )
        try Data([1, 2, 3]).write(to: url)
        return url
    }

    func item(
        id: DictationID = DictationID(),
        date: TimeInterval = 1_000,
        raw: String = "raw",
        final: String = "final",
        kind: HistoryItem.Kind = .dictation,
        instruction: String? = nil,
        audioURL: URL? = nil,
        status: HistoryItem.Status = .inserted,
    ) -> HistoryItem {
        HistoryItem(
            id: id,
            date: Date(timeIntervalSince1970: date),
            appBundleID: "com.apple.Notes",
            appName: "Notes",
            kind: kind,
            rawText: raw,
            finalText: final,
            instruction: instruction,
            audioURL: audioURL,
            duration: .milliseconds(1_500),
            status: status,
        )
    }
}
