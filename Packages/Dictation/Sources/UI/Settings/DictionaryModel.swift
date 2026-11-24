public import Core
import Foundation
public import Observation

@MainActor
@Observable
public final class DictionaryModel {
    public private(set) var words: [Word] = []

    @ObservationIgnored
    private let store: any WordStore

    public init(store: any WordStore) {
        self.store = store
    }

    public func load() async {
        do {
            let all = try await store.all()
            words = all.sorted { $0.text.localizedCompare($1.text) == .orderedAscending }
        } catch {
            UILog.failure("dictionary load", error)
        }
    }

    public func add(_ word: Word) async {
        do {
            try await store.add(word)
        } catch {
            UILog.failure("dictionary add", error)
        }
        await load()
    }

    public func remove(_ word: Word) async {
        do {
            try await store.remove(text: word.text)
        } catch {
            UILog.failure("dictionary remove", error)
        }
        await load()
    }
}
