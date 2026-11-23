import Core
import CoreTesting
import Foundation
import Testing
@testable import UI

@MainActor
internal struct HistoryModelTests {
    private final class Log {
        var copied: [String] = []
        var retried: [DictationID] = []
    }

    private let store = FakeHistoryStore()
    private let log = Log()

    private func makeModel() -> HistoryModel {
        let store = store
        let log = log
        return HistoryModel(
            store: store,
            dictionary: DictionaryModel(store: FakeWordStore()),
            actions: HistoryActions(
                observe: { query in
                    AsyncStream { continuation in
                        Task {
                            let found = (try? await store.search(query, limit: 100)) ?? []
                            continuation.yield(found)
                            continuation.finish()
                        }
                    }
                },
                copy: { log.copied.append($0) },
                retry: { log.retried.append($0) },
            ),
            calendar: Calendar(identifier: .gregorian),
        )
    }

    @Test
    func watchLoadsItemsMatchingTheQuery() async throws {
        try await store.save(UIFixtures.item(final: "Buy milk."))
        try await store.save(UIFixtures.item(final: "Call mom."))
        let model = makeModel()
        model.query = "milk"
        await model.watch()
        #expect(model.items.map(\.finalText) == ["Buy milk."])
    }

    @Test
    func copyPrefersFinalTextAndFallsBackToRaw() {
        let model = makeModel()
        model.copy(UIFixtures.item(raw: "raw words", final: "Final."))
        model.copy(UIFixtures.item(raw: "raw words", final: ""))
        #expect(log.copied == ["Final.", "raw words"])
    }

    @Test
    func retryNeedsKeptAudio() {
        let model = makeModel()
        #expect(!model.canRetry(UIFixtures.item()))
        #expect(model.canRetry(UIFixtures.item(audioURL: URL(filePath: "/tmp/a.caf"))))
    }

    @Test
    func retryForwardsTheItemID() async {
        let model = makeModel()
        let item = UIFixtures.item()
        await model.retry(item)
        #expect(log.retried == [item.id])
    }

    @Test
    func deleteRemovesTheItemFromTheStore() async throws {
        let item = UIFixtures.item()
        try await store.save(item)
        await makeModel().delete(item)
        #expect(store.items.isEmpty)
    }

    @Test
    func togglingExpansionAndOriginalIsIdempotentPerItem() {
        let model = makeModel()
        let item = UIFixtures.item()
        model.toggleExpanded(item)
        #expect(model.expanded == item.id)
        model.toggleExpanded(item)
        #expect(model.expanded == nil)
        model.toggleOriginal(item)
        #expect(model.shownOriginals.contains(item.id))
        model.toggleOriginal(item)
        #expect(model.shownOriginals.isEmpty)
    }
}
