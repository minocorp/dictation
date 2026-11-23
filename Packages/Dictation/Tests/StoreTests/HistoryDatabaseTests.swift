import Core
import Foundation
import GRDB
@testable import Store
import Testing

internal struct HistoryDatabaseTests {
    private let fixtures = HistoryFixtures()

    @Test
    func migrationsCreateEveryTable() async throws {
        let database = try fixtures.makeDatabase()
        let tables = try await database.queue.read { db in
            try String.fetchAll(db, sql: "SELECT name FROM sqlite_master WHERE type = 'table'")
        }
        #expect(
            Set(tables).isSuperset(of: ["dictation", "dictation_fts", "word", "correction"])
        )
    }

    @Test
    func migrationsAreRecordedInOrder() async throws {
        let database = try fixtures.makeDatabase()
        let applied = try await database.queue.read { db in
            try String.fetchAll(db, sql: "SELECT identifier FROM grdb_migrations ORDER BY rowid")
        }
        #expect(
            applied == [
                HistoryMigrations.createDictation,
                HistoryMigrations.createDictationSearch,
                HistoryMigrations.createWordAndCorrection,
                HistoryMigrations.searchWithTrigrams,
            ]
        )
    }

    @Test
    func reopeningKeepsDataAndDoesNotReapplyMigrations() async throws {
        let directory = fixtures.directory.url
        let first = try HistoryDatabase(directory: directory)
        try await GRDBHistoryStore(database: first, retention: { .thirtyDays })
            .save(fixtures.item(raw: "persisted"))
        let second = try HistoryDatabase(directory: directory)
        let found = try await GRDBHistoryStore(database: second, retention: { .thirtyDays })
            .search("persisted", limit: 5)
        #expect(found.count == 1)
    }

    @Test
    func directoryIsOwnerOnlyExcludedFromBackupAndSpotlight() throws {
        let directory = fixtures.directory.url
        _ = try HistoryDatabase(directory: directory)
        let attributes = try FileManager.default.attributesOfItem(atPath: directory.path())
        #expect((attributes[.posixPermissions] as? Int) == 0o700)
        #expect(
            try directory.resourceValues(forKeys: [.isExcludedFromBackupKey]).isExcludedFromBackup
                == true
        )
        #expect(
            FileManager.default.fileExists(
                atPath: directory.appending(path: ".metadata_never_index").path()
            )
        )
        #expect(FileManager.default.fileExists(atPath: directory.appending(path: "Audio").path()))
    }
}
