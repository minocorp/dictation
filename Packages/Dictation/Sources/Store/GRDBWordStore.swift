public import Core
public import Foundation
import GRDB

public final class GRDBWordStore: WordStore {
    private static let promotionThreshold = 2
    private static let correctionWindow: TimeInterval = 30 * 86_400

    private let database: HistoryDatabase
    private let now: @Sendable () -> Date

    public init(database: HistoryDatabase, now: @escaping @Sendable () -> Date) {
        self.database = database
        self.now = now
    }

    public func all() async throws(StoreError) -> [Word] {
        let records = try await database.read { db in
            try WordRecord.order(Column("createdAt").desc, Column("id").desc).fetchAll(db)
        }
        return records.compactMap { record in
            do {
                return try record.word()
            } catch {
                StoreLog.skippedRow(record.text)
                return nil
            }
        }
    }

    public func add(_ word: Word) async throws(StoreError) {
        let record = WordRecord(word, createdAt: now())
        try await database.write { db in try record.insert(db) }
    }

    public func remove(text: String) async throws(StoreError) {
        try await database.write { db in
            _ = try WordRecord.filter(Column("text") == text).deleteAll(db)
        }
    }

    public func recordCorrection(
        from original: String,
        to corrected: String,
    ) async throws(StoreError) -> Word? {
        guard original != corrected else { return nil }
        let seenAt = now()
        return try await database.write { db in
            let count = try Self.incrementCorrection(original, corrected, seenAt: seenAt, in: db)
            guard
                count >= Self.promotionThreshold,
                try Self.wordExists(corrected, in: db) == false
            else { return nil }
            return try Self.promote(original, corrected, seenAt: seenAt, in: db)
        }
    }

    private static func wordExists(_ text: String, in db: Database) throws -> Bool {
        try String.fetchOne(db, sql: "SELECT text FROM word WHERE text = ?", arguments: [text])
            != nil
    }

    private static func incrementCorrection(
        _ original: String,
        _ corrected: String,
        seenAt: Date,
        in db: Database,
    ) throws -> Int {
        let cutoff = seenAt.addingTimeInterval(-Self.correctionWindow)
        try db.execute(sql: "DELETE FROM correction WHERE lastSeenAt < ?", arguments: [cutoff])
        try db.execute(
            sql: """
                INSERT INTO correction (fromText, toText, count, lastSeenAt) VALUES (?, ?, 1, ?)
                ON CONFLICT(fromText, toText) DO UPDATE SET
                    count = count + 1, lastSeenAt = excluded.lastSeenAt
                """,
            arguments: [original, corrected, seenAt],
        )
        return try Int.fetchOne(
            db,
            sql: "SELECT count FROM correction WHERE fromText = ? AND toText = ?",
            arguments: [original, corrected],
        ) ?? 0
    }

    private static func promote(
        _ original: String,
        _ corrected: String,
        seenAt: Date,
        in db: Database,
    ) throws -> Word {
        let word = Word(text: corrected, soundsLike: [original], source: .learned)
        let record = WordRecord(word, createdAt: seenAt)
        try record.insert(db)
        try db.execute(
            sql: "DELETE FROM correction WHERE fromText = ? AND toText = ?",
            arguments: [original, corrected],
        )
        return word
    }
}
