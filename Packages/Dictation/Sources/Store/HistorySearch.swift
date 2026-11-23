import Foundation
import GRDB

internal enum HistorySearch {
    private static let trigramLength = 3

    static func records(
        matching query: String,
        limit: Int,
        in db: Database,
    ) throws
        -> [DictationRecord]
    {
        let tokens = tokens(of: query)
        guard !tokens.isEmpty else {
            return try DictationRecord.order(Column("createdAt").desc).limit(limit).fetchAll(db)
        }
        if tokens.allSatisfy({ $0.unicodeScalars.count >= trigramLength }) {
            return try fullText(tokens, limit: limit, in: db)
        }
        return try substring(tokens, limit: limit, in: db)
    }

    private static func tokens(of query: String) -> [String] {
        query.split { !$0.isLetter && !$0.isNumber }.map(String.init)
    }

    private static func fullText(
        _ tokens: [String],
        limit: Int,
        in db: Database,
    ) throws
        -> [DictationRecord]
    {
        let pattern = try FTS5Pattern(rawPattern: tokens.map { "\"\($0)\"" }.joined(separator: " "))
        return try DictationRecord.fetchAll(
            db,
            sql: """
                SELECT dictation.* FROM dictation
                JOIN dictation_fts ON dictation_fts.rowid = dictation.rowid
                WHERE dictation_fts MATCH ?
                ORDER BY dictation.createdAt DESC LIMIT ?
                """,
            arguments: [pattern, limit],
        )
    }

    private static func substring(
        _ tokens: [String],
        limit: Int,
        in db: Database,
    ) throws
        -> [DictationRecord]
    {
        let condition = tokens.map { _ in "(rawText LIKE ? OR finalText LIKE ?)" }
            .joined(separator: " AND ")
        let patterns: [any DatabaseValueConvertible] =
            tokens.flatMap { ["%\($0)%", "%\($0)%"] } + [limit]
        return try DictationRecord.fetchAll(
            db,
            sql: "SELECT * FROM dictation WHERE \(condition) ORDER BY createdAt DESC LIMIT ?",
            arguments: StatementArguments(patterns),
        )
    }
}
