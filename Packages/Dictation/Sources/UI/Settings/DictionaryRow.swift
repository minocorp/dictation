import Core
import SwiftUI

internal struct DictionaryRow: View {
    let word: Word
    let remove: () -> Void

    var body: some View {
        HStack {
            Text(verbatim: word.text)
            if !word.soundsLike.isEmpty {
                Text(verbatim: word.soundsLike.joined(separator: ", "))
                    .foregroundStyle(.secondary)
            }
            if word.source == .learned {
                Text(UIString.dictionaryLearned)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 6)
                    .background(.quaternary, in: Capsule())
            }
            Spacer()
            Button(UIString.dictionaryRemove, role: .destructive, action: remove)
                .buttonStyle(.borderless)
        }
    }
}
