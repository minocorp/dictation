import Core
import Foundation
import Store

internal struct AppStores: Sendable {
    let history: GRDBHistoryStore
    let words: GRDBWordStore
    let retention: HistoryRetentionJob

    static func make(paths: AppPaths, preferences: PreferencesStore) -> AppStores {
        let database = openDatabase(paths: paths)
        let history = GRDBHistoryStore(
            database: database,
            retention: { preferences.read().historyRetention },
        )
        let words = GRDBWordStore(database: database, now: { Date() })
        let retention = HistoryRetentionJob(
            store: history,
            retention: { preferences.read().historyRetention },
            clock: ContinuousClock(),
            now: { Date() },
        )
        return AppStores(history: history, words: words, retention: retention)
    }

    private static func openDatabase(paths: AppPaths) -> HistoryDatabase {
        do {
            return try HistoryDatabase(directory: paths.data)
        } catch {
            AppLog.failure("open history database", error)
            return fallbackDatabase()
        }
    }

    private static func fallbackDatabase() -> HistoryDatabase {
        let audio = FileManager.default.temporaryDirectory.appending(path: "dictation-audio")
        do {
            return try HistoryDatabase(inMemoryWithAudioDirectory: audio)
        } catch {
            preconditionFailure("in-memory history database must open: \(error)")
        }
    }
}
