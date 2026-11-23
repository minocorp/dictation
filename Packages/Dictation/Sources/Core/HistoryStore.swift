public import Foundation

public protocol HistoryStore: Sendable {
    func save(_ item: HistoryItem) async throws(StoreError)
    func update(_ item: HistoryItem) async throws(StoreError)
    func item(id: DictationID) async throws(StoreError) -> HistoryItem
    func pending() async throws(StoreError) -> [HistoryItem]
    func search(_ query: String, limit: Int) async throws(StoreError) -> [HistoryItem]
    func delete(id: DictationID) async throws(StoreError)
    func deleteAll() async throws(StoreError)
    func orphanAudio() async throws(StoreError) -> [URL]
    func purge(olderThan date: Date) async throws(StoreError)
}
