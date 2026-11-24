import Core
import Foundation

internal struct WordDraft: Equatable {
    var text = ""
    var soundsLike = ""

    var word: Word? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let soundAlikes = soundsLike.split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        return Word(text: trimmed, soundsLike: soundAlikes, source: .manual)
    }
}
