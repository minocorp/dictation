public import Core
public import Foundation
import Synchronization

public final class FakeHistoryStore: HistoryStore {
    private struct State {
        var items: [DictationID: HistoryItem] = [:]
        var orphans: [URL] = []
        var failure: StoreError?
        var purgeCutoffs: [Date] = []
    }

    private let state = Mutex(State())

    public var failure: StoreError? {
        get { state.withLock { $0.failure } }
        set { state.withLock { $0.failure = newValue } }
    }

    public var orphans: [URL] {
        get { state.withLock { $0.orphans } }
        set { state.withLock { $0.orphans = newValue } }
    }

    public var items: [HistoryItem] {
        state.withLock { $0.items.values.sorted { $0.date < $1.date } }
    }

    public var purgeCutoffs: [Date] { state.withLock { $0.purgeCutoffs } }

    public init() {}

    public func save(_ item: HistoryItem) async throws(StoreError) {
        try write { $0.items[item.id] = item }
    }

    public func update(_ item: HistoryItem) async throws(StoreError) {
        let exists = state.withLock { $0.items[item.id] != nil }
        guard exists else { throw .notFound }
        try write { $0.items[item.id] = item }
    }

    public func item(id: DictationID) async throws(StoreError) -> HistoryItem {
        try read { state in
            guard let item = state.items[id] else { return .failure(.notFound) }
            return .success(item)
        }
    }

    public func pending() async throws(StoreError) -> [HistoryItem] {
        try read { state in
            .success(
                state.items.values.filter { $0.status == .pending }.sorted { $0.date < $1.date }
            )
        }
    }

    public func search(_ query: String, limit: Int) async throws(StoreError) -> [HistoryItem] {
        try read { state in
            let matches = state.items.values.filter { item in
                query.isEmpty
                    || item.rawText.localizedCaseInsensitiveContains(query)
                    || item.finalText.localizedCaseInsensitiveContains(query)
            }
            return .success(Array(matches.sorted { $0.date > $1.date }.prefix(limit)))
        }
    }

    public func delete(id: DictationID) async throws(StoreError) {
        try write { $0.items[id] = nil }
    }

    public func deleteAll() async throws(StoreError) {
        try write { $0.items = [:] }
    }

    public func orphanAudio() async throws(StoreError) -> [URL] {
        try read { .success($0.orphans) }
    }

    public func purge(olderThan date: Date) async throws(StoreError) {
        try write { state in
            state.purgeCutoffs.append(date)
            state.items = state.items.filter { $0.value.date >= date }
        }
    }

    private func write(_ change: (inout State) -> Void) throws(StoreError) {
        let failure = state.withLock { state -> StoreError? in
            if let failure = state.failure { return failure }
            change(&state)
            return nil
        }
        if let failure { throw failure }
    }

    private func read<T>(_ query: (State) -> Result<T, StoreError>) throws(StoreError) -> T {
        let result = state.withLock { state -> Result<T, StoreError> in
            if let failure = state.failure { return .failure(failure) }
            return query(state)
        }
        return try result.get()
    }
}
