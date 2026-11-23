import Core
@testable import Diagnostics
import Foundation
import Testing

internal struct InsertionResultLogTests {
    private let directory = TestDirectory()

    private var fileURL: URL { directory.url.appending(path: "insertion-results.json") }

    @Test
    func countsOutcomesPerBundleID() {
        let log = InsertionResultLog(fileURL: fileURL)
        log.record(bundleID: "com.apple.Notes", outcome: .inserted(.pasteShortcut))
        log.record(bundleID: "com.apple.Notes", outcome: .inserted(.pasteShortcut))
        log.record(bundleID: "com.apple.Notes", outcome: .copied(.noTextField))
        log.record(bundleID: "com.example.Bank", outcome: .refused(.secureField))
        #expect(
            log.snapshot() == [
                "com.apple.Notes": ["inserted.pasteShortcut": 2, "copied.noTextField": 1],
                "com.example.Bank": ["refused.secureField": 1],
            ]
        )
    }

    @Test
    func countsSurviveRelaunch() {
        InsertionResultLog(fileURL: fileURL)
            .record(bundleID: "com.apple.Notes", outcome: .inserted(.typedUnicode))
        let reopened = InsertionResultLog(fileURL: fileURL)
        reopened.record(bundleID: "com.apple.Notes", outcome: .inserted(.typedUnicode))
        #expect(reopened.snapshot()["com.apple.Notes"]?["inserted.typedUnicode"] == 2)
    }

    @Test
    func corruptStoreStartsEmpty() throws {
        try FileManager.default.createDirectory(
            at: directory.url,
            withIntermediateDirectories: true,
        )
        try Data("not json".utf8).write(to: fileURL)
        #expect(InsertionResultLog(fileURL: fileURL).snapshot().isEmpty)
    }
}
