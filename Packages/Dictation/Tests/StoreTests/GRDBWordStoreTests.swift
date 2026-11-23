import Core
import Foundation
@testable import Store
import Synchronization
import Testing

internal struct GRDBWordStoreTests {
    private let fixtures = HistoryFixtures()

    private func makeStore() throws -> GRDBWordStore {
        GRDBWordStore(
            database: try fixtures.makeDatabase(),
            now: { Date(timeIntervalSince1970: 1) },
        )
    }

    @Test
    func wordsAreListedNewestFirst() async throws {
        let store = try makeStore()
        try await store.add(Word(text: "Zohn", soundsLike: ["zone"], source: .manual))
        try await store.add(Word(text: "Anthropic", soundsLike: [], source: .manual))
        #expect(try await store.all().map(\.text) == ["Anthropic", "Zohn"])
    }

    @Test
    func addingSameTextReplacesTheEntry() async throws {
        let store = try makeStore()
        try await store.add(Word(text: "Zohn", soundsLike: ["zone"], source: .manual))
        let replacement = Word(text: "Zohn", soundsLike: ["john", "zon"], source: .learned)
        try await store.add(replacement)
        #expect(try await store.all() == [replacement])
    }

    @Test
    func removeDeletesWord() async throws {
        let store = try makeStore()
        try await store.add(Word(text: "Zohn", soundsLike: [], source: .manual))
        try await store.remove(text: "Zohn")
        #expect(try await store.all().isEmpty)
    }

    @Test
    func secondIdenticalCorrectionPromotesTheWord() async throws {
        let store = try makeStore()
        #expect(try await store.recordCorrection(from: "zone", to: "Zohn") == nil)
        let promoted = try await store.recordCorrection(from: "zone", to: "Zohn")
        #expect(promoted == Word(text: "Zohn", soundsLike: ["zone"], source: .learned))
        #expect(try await store.all() == [try #require(promoted)])
    }

    @Test
    func differentCorrectionsDoNotAccumulate() async throws {
        let store = try makeStore()
        #expect(try await store.recordCorrection(from: "zone", to: "Zohn") == nil)
        #expect(try await store.recordCorrection(from: "john", to: "Zohn") == nil)
        #expect(try await store.all().isEmpty)
    }

    @Test
    func existingWordIsNotPromotedAgain() async throws {
        let store = try makeStore()
        try await store.add(Word(text: "Zohn", soundsLike: [], source: .manual))
        _ = try await store.recordCorrection(from: "zone", to: "Zohn")
        #expect(try await store.recordCorrection(from: "zone", to: "Zohn") == nil)
        #expect(try await store.all().map(\.source) == [.manual])
    }

    @Test
    func removedLearnedWordNeedsTwoFreshCorrections() async throws {
        let store = try makeStore()
        _ = try await store.recordCorrection(from: "zone", to: "Zohn")
        _ = try await store.recordCorrection(from: "zone", to: "Zohn")
        try await store.remove(text: "Zohn")
        #expect(try await store.recordCorrection(from: "zone", to: "Zohn") == nil)
    }

    @Test
    func unchangedTextIsNotACorrection() async throws {
        let store = try makeStore()
        #expect(try await store.recordCorrection(from: "same", to: "same") == nil)
        #expect(try await store.recordCorrection(from: "same", to: "same") == nil)
        #expect(try await store.all().isEmpty)
    }

    @Test
    func correctionsFarApartDoNotAccumulate() async throws {
        let clock = Mutex(Date(timeIntervalSince1970: 0))
        let store = GRDBWordStore(
            database: try fixtures.makeDatabase(),
            now: { clock.withLock { $0 } },
        )
        #expect(try await store.recordCorrection(from: "zone", to: "Zohn") == nil)
        clock.withLock { $0 = Date(timeIntervalSince1970: 31 * 86_400) }
        #expect(try await store.recordCorrection(from: "zone", to: "Zohn") == nil)
        #expect(try await store.recordCorrection(from: "zone", to: "Zohn") != nil)
    }
}
