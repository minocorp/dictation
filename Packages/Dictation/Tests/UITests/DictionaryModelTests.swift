import Core
import CoreTesting
import Testing
@testable import UI

@MainActor
internal struct DictionaryModelTests {
    private let store = FakeWordStore()

    @Test
    func draftTrimsTheWordAndSplitsSoundAlikes() {
        let draft = WordDraft(text: " Supabase ", soundsLike: "super base, soup a base,")
        #expect(
            draft.word
                == Word(
                    text: "Supabase",
                    soundsLike: ["super base", "soup a base"],
                    source: .manual,
                )
        )
    }

    @Test
    func blankDraftHasNoWord() {
        #expect(WordDraft(text: "   ", soundsLike: "x").word == nil)
    }

    @Test
    func addStoresTheWordAndReloads() async {
        let word = Word(text: "Supabase", soundsLike: [], source: .manual)
        let model = DictionaryModel(store: store)
        await model.add(word)
        #expect(store.words == [word])
        #expect(model.words == [word])
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
