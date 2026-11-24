import Core
import SwiftUI

internal struct DictionaryPane: View {
    @Bindable
    var settings: SettingsModel
    @Bindable
    var model: DictionaryModel
    @State
    private var draft = WordDraft()

    var body: some View {
        Form {
            Section {
                Toggle(UIString.dictionaryLearning, isOn: $settings.preferences.learning)
            }
            Section {
                TextField(
                    UIString.dictionaryWord,
                    text: $draft.text,
                    prompt: Text(UIString.dictionaryWordExample),
                )
                TextField(
                    UIString.dictionarySoundsLike,
                    text: $draft.soundsLike,
                    prompt: Text(UIString.dictionarySoundsLikeExample),
                )
                Button(UIString.dictionaryAdd) {
                    guard let word = draft.word else { return }
                    draft = WordDraft()
                    Task { await model.add(word) }
                }
                .disabled(draft.word == nil)
            }
            Section {
                ForEach(model.words, id: \.text) { word in
                    DictionaryRow(word: word) {
                        Task { await model.remove(word) }
                    }
                }
            }
        }
        .formStyle(.grouped)
        .task { await model.load() }
    }
}
