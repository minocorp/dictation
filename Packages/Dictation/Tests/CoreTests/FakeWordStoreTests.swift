import Core
import CoreTesting
import Testing

internal struct FakeWordStoreTests {
    private let store = FakeWordStore()

    @Test
    func promotesCorrectionOnSecondOccurrence() async throws {
        let first = try await store.recordCorrection(from: "super base", to: "Supabase")
        let second = try await store.recordCorrection(from: "super base", to: "Supabase")
        #expect(first == nil)
        #expect(second == Word(text: "Supabase", soundsLike: ["super base"], source: .learned))
        #expect(try await store.all() == [second].compactMap { $0 })
    }

    @Test
    func differentCorrectionsAreCountedSeparately() async throws {
        _ = try await store.recordCorrection(from: "a", to: "B")
        let other = try await store.recordCorrection(from: "c", to: "B")
        #expect(other == nil)
    }

    @Test
    func failureIsThrown() async {
        store.failure = .writeFailed(code: 1)
        await #expect(throws: StoreError.writeFailed(code: 1)) {
            try await store.add(Word(text: "x", soundsLike: [], source: .manual))
        }
    }
}
