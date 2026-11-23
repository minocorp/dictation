import Core
import Foundation
import GRDB
@testable import Store
import Testing

internal struct GRDBHistoryStoreTests {
    private let fixtures = HistoryFixtures()

    private func makeStore(retention: HistoryRetention = .thirtyDays) throws -> GRDBHistoryStore {
        GRDBHistoryStore(database: try fixtures.makeDatabase(), retention: { retention })
    }

    @Test
    func savedItemRoundTripsEveryField() async throws {
        let store = try makeStore()
        let audio = try fixtures.writeAudio(named: "round-trip")
        let item = fixtures.item(
            raw: "um hello",
            final: "Hello.",
            kind: .edit,
            instruction: "make it formal",
            audioURL: audio,
            status: .copied,
        )
        try await store.save(item)
        #expect(try await store.item(id: item.id) == item)
    }

    @Test
    func updateOfMissingItemThrowsNotFound() async throws {
        let store = try makeStore()
        await #expect(throws: StoreError.notFound) {
            try await store.update(fixtures.item())
        }
    }

    @Test
    func updateReplacesFinalTextAndStatus() async throws {
        let store = try makeStore()
        let pending = fixtures.item(status: .pending)
        try await store.save(pending)
        let finished = fixtures.item(id: pending.id, final: "Done.", status: .inserted)
        try await store.update(finished)
        #expect(try await store.item(id: pending.id) == finished)
    }

    @Test
    func pendingIsOldestFirst() async throws {
        let store = try makeStore()
        try await store.save(fixtures.item(date: 5, status: .pending))
        try await store.save(fixtures.item(date: 1, status: .pending))
        try await store.save(fixtures.item(date: 3, status: .inserted))
        let dates = try await store.pending().map(\.date.timeIntervalSince1970)
        #expect(dates == [1, 5])
    }

    @Test
    func searchMatchesRawAndFinalTextNewestFirst() async throws {
        let store = try makeStore()
        try await store.save(fixtures.item(date: 1, raw: "hello world", final: "Hello world."))
        try await store.save(fixtures.item(date: 2, raw: "other", final: "Other."))
        try await store.save(fixtures.item(date: 3, raw: "um hello", final: "Hello."))
        let dates = try await store.search("hello", limit: 10).map(\.date.timeIntervalSince1970)
        #expect(dates == [3, 1])
    }

    @Test
    func searchMatchesPrefixesAndKorean() async throws {
        let store = try makeStore()
        try await store.save(fixtures.item(raw: "안녕하세요 여러분", final: "안녕하세요, 여러분."))
        #expect(try await store.search("안녕", limit: 10).count == 1)
        #expect(try await store.search("여러", limit: 10).count == 1)
        #expect(try await store.search("없는말", limit: 10).isEmpty)
    }

    @Test
    func searchIgnoresFTSSyntaxCharacters() async throws {
        let store = try makeStore()
        try await store.save(fixtures.item(raw: "plain text"))
        #expect(try await store.search("\"plain (tex", limit: 10).count == 1)
    }

    @Test
    func searchRespectsLimitAndEmptyQueryListsNewest() async throws {
        let store = try makeStore()
        for date in 1...5 {
            try await store.save(fixtures.item(date: TimeInterval(date)))
        }
        let dates = try await store.search("", limit: 2).map(\.date.timeIntervalSince1970)
        #expect(dates == [5, 4])
    }

    @Test
    func searchSeesUpdatedAndDeletedText() async throws {
        let store = try makeStore()
        let item = fixtures.item(raw: "before", final: "before")
        try await store.save(item)
        try await store.update(fixtures.item(id: item.id, raw: "after", final: "after"))
        #expect(try await store.search("before", limit: 5).isEmpty)
        #expect(try await store.search("after", limit: 5).count == 1)
        try await store.delete(id: item.id)
        #expect(try await store.search("after", limit: 5).isEmpty)
    }

    @Test
    func deleteRemovesRowAndAudio() async throws {
        let store = try makeStore()
        let audio = try fixtures.writeAudio(named: "delete-me")
        let item = fixtures.item(audioURL: audio)
        try await store.save(item)
        try await store.delete(id: item.id)
        await #expect(throws: StoreError.notFound) { try await store.item(id: item.id) }
        #expect(!FileManager.default.fileExists(atPath: audio.path()))
    }

    @Test
    func deleteAllRemovesRowsAndTheirAudio() async throws {
        let store = try makeStore()
        let audio = try fixtures.writeAudio(named: "clear-me")
        try await store.save(fixtures.item(audioURL: audio))
        try await store.deleteAll()
        #expect(try await store.search("", limit: 10).isEmpty)
        #expect(!FileManager.default.fileExists(atPath: audio.path()))
    }

    @Test
    func finishedItemWithRetentionOffLeavesNoRowAndNoAudio() async throws {
        let store = try makeStore(retention: .off)
        let audio = try fixtures.writeAudio(named: "off")
        let item = fixtures.item(audioURL: audio, status: .inserted)
        try await store.save(item)
        #expect(!FileManager.default.fileExists(atPath: audio.path()))
        await #expect(throws: StoreError.notFound) { try await store.item(id: item.id) }
    }

    @Test
    func pendingItemFinishedWithRetentionOffIsPurgedOnUpdate() async throws {
        let store = try makeStore(retention: .off)
        let pending = fixtures.item(raw: "x", status: .pending)
        try await store.save(pending)
        try await store.update(fixtures.item(id: pending.id, raw: "x", status: .inserted))
        #expect(try await store.search("", limit: 10).isEmpty)
    }

    @Test
    func searchFindsKoreanInsideAWordAndShortQueries() async throws {
        let store = try makeStore()
        try await store.save(fixtures.item(raw: "회의록정리", final: "회의록 정리."))
        #expect(try await store.search("의록", limit: 10).count == 1)
        #expect(try await store.search("록정", limit: 10).count == 1)
        #expect(try await store.search("정", limit: 10).count == 1)
        #expect(try await store.search("회의록정", limit: 10).count == 1)
        #expect(try await store.search("없음", limit: 10).isEmpty)
    }

    @Test
    func searchMatchesLatinInsideAWord() async throws {
        let store = try makeStore()
        try await store.save(fixtures.item(raw: "meeting notes"))
        #expect(try await store.search("eeti", limit: 10).count == 1)
        #expect(try await store.search("NOTES", limit: 10).count == 1)
    }

    @Test
    func unreadableRowIsSkippedNotFatal() async throws {
        let database = try fixtures.makeDatabase()
        let store = GRDBHistoryStore(database: database, retention: { .thirtyDays })
        try await store.save(fixtures.item(raw: "good"))
        try await database.queue.write { db in
            try db.execute(
                sql: """
                    INSERT INTO dictation (id, createdAt, appBundleID, appName, kind, rawText,
                        finalText, durationMs, status)
                    VALUES ('not-a-valid-id', 0, 'a', 'a', 'bogus', 'bad', 'bad', 0, 'inserted')
                    """
            )
        }
        #expect(try await store.search("", limit: 10).map(\.rawText) == ["good"])
    }

    @Test
    func pendingItemWithRetentionOffKeepsAudio() async throws {
        let store = try makeStore(retention: .off)
        let audio = try fixtures.writeAudio(named: "off-pending")
        let item = fixtures.item(audioURL: audio, status: .pending)
        try await store.save(item)
        #expect(FileManager.default.fileExists(atPath: audio.path()))
        #expect(try await store.item(id: item.id).audioURL == audio)
    }

    @Test
    func historyStreamEmitsOnEveryChange() async throws {
        let store = try makeStore()
        var snapshots = store.history(matching: "", limit: 10).makeAsyncIterator()
        #expect(await snapshots.next()?.isEmpty == true)
        try await store.save(fixtures.item(raw: "first"))
        #expect(await snapshots.next()?.count == 1)
    }
}
