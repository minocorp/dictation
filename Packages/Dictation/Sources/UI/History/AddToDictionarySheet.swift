import Core
import SwiftUI

internal struct AddToDictionarySheet: View {
    let model: DictionaryModel
    let item: HistoryItem
    let close: () -> Void
    @State
    private var draft = WordDraft()

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
                        draft.text = word.trimmingCharacters(in: .punctuationCharacters)
                    } label: {
                        Text(verbatim: word)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }
            TextField(UIString.dictionaryWord, text: $draft.text)
            TextField(UIString.dictionarySoundsLike, text: $draft.soundsLike)
            HStack {
                Spacer()
                Button(UIString.historyDictionaryCancel, action: close)
                    .keyboardShortcut(.cancelAction)
                Button(UIString.historyDictionaryAdd) {
                    guard let word = draft.word else { return }
                    Task {
                        await model.add(word)
                        close()
                    }
                }
                .keyboardShortcut(.defaultAction)
                .disabled(draft.word == nil)
            }
        }
        .padding(20)
        .frame(width: 420)
    }
}
