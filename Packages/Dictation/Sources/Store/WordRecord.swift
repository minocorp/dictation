import Core
import Foundation
import GRDB

internal struct WordRecord: Codable, FetchableRecord, PersistableRecord, Sendable {
    static let databaseTableName = "word"
    static let persistenceConflictPolicy = PersistenceConflictPolicy(
        insert: .replace,
        update: .replace,
    )

    var text: String
    var soundsLike: [String]
    var source: String
    var createdAt: Date

    init(_ word: Word, createdAt: Date) {
        text = word.text
        soundsLike = word.soundsLike
        source = word.source.rawValue
        self.createdAt = createdAt
    }

    func word() throws(StoreError) -> Word {
        guard let source = Word.Source(rawValue: source) else { throw .readFailed(code: 0) }
        return Word(text: text, soundsLike: soundsLike, source: source)
    }
}
