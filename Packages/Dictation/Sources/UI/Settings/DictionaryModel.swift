public import Core
import Foundation
public import Observation

@MainActor
@Observable
public final class DictionaryModel {
    public private(set) var words: [Word] = []
    public var newWord = ""
    public var newSoundsLike = ""

    @ObservationIgnored
    private let store: any WordStore

    public init(store: any WordStore) {
        self.store = store
    }

    var canAdd: Bool {
        !newWord.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    public func load() async {
        do {
            let all = try await store.all()
            words = all.sorted { $0.text.localizedCompare($1.text) == .orderedAscending }
        } catch {
            UILog.failure("dictionary load", error)
        }
    }

    public func addTypedWord() async {
        let text = newWord.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        let soundAlikes = newSoundsLike.split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        await add(Word(text: text, soundsLike: soundAlikes, source: .manual))
        newWord = ""
        newSoundsLike = ""
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
