import Core
import CoreTesting
import Foundation
import Testing

internal struct FakeHistoryStoreTests {
    private let store = FakeHistoryStore()

    @Test
    func searchMatchesRawAndFinalTextNewestFirst() async throws {
        try await store.save(item(date: 1, raw: "hello world", final: "Hello world."))
        try await store.save(item(date: 2, raw: "other", final: "Other."))
        try await store.save(item(date: 3, raw: "um hello", final: "Hello."))
        let found = try await store.search("hello", limit: 10)
        #expect(
            found.map(\.date) == [Date(timeIntervalSince1970: 3), Date(timeIntervalSince1970: 1)]
        )
    }

    @Test
    func pendingIsOldestFirst() async throws {
        try await store.save(item(date: 5, status: .pending))
        try await store.save(item(date: 1, status: .pending))
        try await store.save(item(date: 3, status: .inserted))
        let pending = try await store.pending()
        #expect(
            pending.map(\.date) == [Date(timeIntervalSince1970: 1), Date(timeIntervalSince1970: 5)]
        )
    }

    @Test
    func updateOfMissingItemThrowsNotFound() async {
        await #expect(throws: StoreError.notFound) {
            try await store.update(item(date: 1))
        }
    }

    @Test
    func purgeDropsItemsOlderThanCutoff() async throws {
        try await store.save(item(date: 1))
        try await store.save(item(date: 10))
        try await store.purge(olderThan: Date(timeIntervalSince1970: 5))
        #expect(store.items.map(\.date) == [Date(timeIntervalSince1970: 10)])
    }

    private func item(
        date: TimeInterval,
        raw: String = "raw",
        final: String = "final",
        status: HistoryItem.Status = .inserted,
    ) -> HistoryItem {
        HistoryItem(
            id: DictationID(),
            date: Date(timeIntervalSince1970: date),
            appBundleID: "com.apple.Notes",
            appName: "Notes",
            kind: .dictation,
            rawText: raw,
            finalText: final,
            instruction: nil,
            audioURL: nil,
            duration: .seconds(1),
            status: status,
        )
    }
}
