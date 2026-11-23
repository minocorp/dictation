@testable import Diagnostics
import Foundation
import Testing

internal struct DiagnosticsLogTests {
    private let directory = TestDirectory()

    private func makeLog(maxBytes: Int = 1_000) -> DiagnosticsLog {
        DiagnosticsLog(
            directory: directory.url,
            maxBytes: maxBytes,
            now: { Date(timeIntervalSince1970: 0) },
        )
    }

    private func text(_ log: DiagnosticsLog) -> String {
        String(data: log.recentLog(), encoding: .utf8) ?? ""
    }

    @Test
    func linesCarryTimeLevelCategoryAndMessage() {
        let log = makeLog()
        log.info("Insertion", "inserted via pasteShortcut in 12 ms")
        #expect(
            text(log) == "1970-01-01T00:00:00Z info Insertion inserted via pasteShortcut in 12 ms\n"
        )
    }

    @Test
    func newlinesInMessagesCannotForgeLogLines() {
        let log = makeLog()
        log.error("Cleanup", "failed\n1970-01-01T00:00:00Z info Fake forged")
        #expect(text(log).split(separator: "\n").count == 1)
    }

    @Test
    func fileStaysUnderTwiceTheCapAcrossRotation() throws {
        let log = makeLog(maxBytes: 1_000)
        for index in 0..<500 {
            log.debug("Store", "entry number \(index) with some padding text")
        }
        let sizes = try FileManager.default.contentsOfDirectory(atPath: directory.url.path())
            .map {
                try
                    FileManager.default
                    .attributesOfItem(atPath: directory.url.appending(path: $0).path())[.size]
                    as? Int
            }
        #expect(sizes.count == 2)
        #expect(sizes.allSatisfy { ($0 ?? .max) < 1_100 })
    }

    @Test
    func recentLogKeepsTheNewestEntriesOnly() {
        let log = makeLog(maxBytes: 1_000)
        for index in 0..<500 {
            log.info("Store", "entry \(index)")
        }
        let recent = text(log)
        #expect(recent.contains("entry 499"))
        #expect(!recent.contains("entry 0\n"))
        #expect(log.recentLog().count <= 1_000)
    }

    @Test
    func concurrentWritersDoNotLoseLines() async {
        let log = makeLog(maxBytes: 1_000_000)
        await withTaskGroup(of: Void.self) { group in
            for index in 0..<50 {
                group.addTask { log.info("Store", "line \(index)") }
            }
        }
        #expect(text(log).split(separator: "\n").count == 50)
    }
}
