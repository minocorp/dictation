import GRDB

internal enum HistoryMigrations {
    static let createDictation = "createDictation"
    static let createDictationSearch = "createDictationSearch"
    static let createWordAndCorrection = "createWordAndCorrection"
    static let searchWithTrigrams = "searchWithTrigrams"

    static var migrator: DatabaseMigrator {
        var migrator = DatabaseMigrator()
        migrator.registerMigration(createDictation) { db in
            try db.create(table: "dictation") { table in
                table.primaryKey("id", .text)
                table.column("createdAt", .datetime).notNull().indexed()
                table.column("appBundleID", .text).notNull()
                table.column("appName", .text).notNull()
                table.column("kind", .text).notNull()
                table.column("rawText", .text).notNull()
                table.column("finalText", .text).notNull()
                table.column("instruction", .text)
                table.column("audioPath", .text)
                table.column("durationMs", .integer).notNull()
                table.column("status", .text).notNull().indexed()
            }
        }
        migrator.registerMigration(createDictationSearch) { db in
            try db.create(virtualTable: "dictation_fts", using: FTS5()) { table in
                table.synchronize(withTable: "dictation")
                table.tokenizer = .unicode61()
                table.column("rawText")
                table.column("finalText")
            }
        }
        migrator.registerMigration(createWordAndCorrection) { db in
            try db.create(table: "word") { table in
                table.autoIncrementedPrimaryKey("id")
                table.column("text", .text).notNull().unique()
                table.column("soundsLike", .jsonText).notNull()
                table.column("source", .text).notNull()
                table.column("createdAt", .datetime).notNull()
            }
            try db.create(table: "correction") { table in
                table.column("fromText", .text).notNull()
                table.column("toText", .text).notNull()
                table.column("count", .integer).notNull()
                table.column("lastSeenAt", .datetime).notNull()
                table.primaryKey(["fromText", "toText"])
            }
        }
        migrator.registerMigration(searchWithTrigrams) { db in
            try db.dropFTS5SynchronizationTriggers(forTable: "dictation_fts")
            try db.drop(table: "dictation_fts")
            try db.create(virtualTable: "dictation_fts", using: FTS5()) { table in
                table.synchronize(withTable: "dictation")
                table.tokenizer = FTS5TokenizerDescriptor(components: ["trigram"])
                table.column("rawText")
                table.column("finalText")
            }
        }
        return migrator
    }
}
