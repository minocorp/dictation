import Core
import SwiftUI

internal struct AddToDictionarySheet: View {
    @Bindable
    var model: DictionaryModel
    let item: HistoryItem
    let close: () -> Void

    private var words: [String] {
        let text = item.finalText.isEmpty ? item.rawText : item.finalText
        return text.split(whereSeparator: \.isWhitespace).map { String($0) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(UIString.historyDictionaryTitle)
                .font(.headline)
            FlowLayout(spacing: 6) {
                ForEach(Array(words.enumerated()), id: \.offset) { _, word in
                    Button {
                        model.newWord = word.trimmingCharacters(in: .punctuationCharacters)
                    } label: {
                        Text(verbatim: word)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }
            TextField(UIString.dictionaryWord, text: $model.newWord)
            TextField(UIString.dictionarySoundsLike, text: $model.newSoundsLike)
            HStack {
                Spacer()
                Button(UIString.historyDictionaryCancel, action: close)
                    .keyboardShortcut(.cancelAction)
                Button(UIString.historyDictionaryAdd) {
                    Task {
                        await model.addTypedWord()
                        close()
                    }
                }
                .keyboardShortcut(.defaultAction)
                .disabled(!model.canAdd)
            }
        }
        .padding(20)
        .frame(width: 420)
    }
}
