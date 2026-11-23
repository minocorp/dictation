import Core
import SwiftUI

internal struct DictionaryPane: View {
    @Bindable
    var settings: SettingsModel
    @Bindable
    var model: DictionaryModel

    var body: some View {
        Form {
            Section {
                Toggle(UIString.dictionaryLearning, isOn: $settings.preferences.learning)
            }
            Section {
                TextField(
                    UIString.dictionaryWord,
                    text: $model.newWord,
                    prompt: Text(UIString.dictionaryWordExample),
                )
                TextField(
                    UIString.dictionarySoundsLike,
                    text: $model.newSoundsLike,
                    prompt: Text(UIString.dictionarySoundsLikeExample),
                )
                Button(UIString.dictionaryAdd) {
                    Task { await model.addTypedWord() }
                }
                .disabled(!model.canAdd)
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
