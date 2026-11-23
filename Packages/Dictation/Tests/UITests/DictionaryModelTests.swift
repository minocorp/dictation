import Core
import CoreTesting
import Testing
@testable import UI

@MainActor
internal struct DictionaryModelTests {
    private let store = FakeWordStore()

    @Test
    func typedWordIsAddedWithSplitSoundAlikes() async {
        let model = DictionaryModel(store: store)
        model.newWord = " Supabase "
        model.newSoundsLike = "super base, soup a base,"
        await model.addTypedWord()
        #expect(
            store.words == [
                Word(text: "Supabase", soundsLike: ["super base", "soup a base"], source: .manual)
            ]
        )
        #expect(model.newWord.isEmpty)
        #expect(model.words.count == 1)
    }

    @Test
    func blankWordIsNotAddable() async {
        let model = DictionaryModel(store: store)
        model.newWord = "   "
        #expect(!model.canAdd)
        await model.addTypedWord()
        #expect(store.words.isEmpty)
    }

    @Test
    func removeDeletesTheWord() async {
        let word = Word(text: "minodevss", soundsLike: [], source: .manual)
        let model = DictionaryModel(store: store)
        await model.add(word)
        await model.remove(word)
        #expect(model.words.isEmpty)
    }
}
