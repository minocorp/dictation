public import Core
public import Foundation
import GRDB

public final class GRDBHistoryStore: HistoryStore {
    private let database: HistoryDatabase
    private let retention: @Sendable () -> HistoryRetention

    private var audio: AudioFiles { AudioFiles(directory: database.audioDirectory) }

    public init(database: HistoryDatabase, retention: @escaping @Sendable () -> HistoryRetention) {
        self.database = database
        self.retention = retention
    }

    public func save(_ item: HistoryItem) async throws(StoreError) {
        let record = storedRecord(for: item)
        try await database.write { db in try record.save(db) }
        try await finishWrite(of: item)
    }

    public func update(_ item: HistoryItem) async throws(StoreError) {
        let record = storedRecord(for: item)
        try await database.write { db in try record.update(db) }
        try await finishWrite(of: item)
    }

    public func item(id: DictationID) async throws(StoreError) -> HistoryItem {
        let directory = database.audioDirectory
        let record = try await database.read { db in try DictationRecord.fetchOne(db, key: id.stem)
        }
        guard let record else { throw .notFound }
        return try record.item(audioDirectory: directory)
    }

    public func pending() async throws(StoreError) -> [HistoryItem] {
        let directory = database.audioDirectory
        let records = try await database.read { db in
            try DictationRecord
                .filter(Column("status") == HistoryItem.Status.pending.rawValue)
                .order(Column("createdAt"))
                .fetchAll(db)
        }
        return Self.items(from: records, audioDirectory: directory)
    }

    public func search(_ query: String, limit: Int) async throws(StoreError) -> [HistoryItem] {
        let directory = database.audioDirectory
        let records = try await database.read { db in
            try HistorySearch.records(matching: query, limit: limit, in: db)
        }
        return Self.items(from: records, audioDirectory: directory)
    }

    public func delete(id: DictationID) async throws(StoreError) {
        let names = try await database.write { db in
            guard let record = try DictationRecord.fetchOne(db, key: id.stem) else {
                return [String]()
            }
            _ = try record.delete(db)
            return record.audioPath.map { [$0] } ?? []
        }
        try audio.remove(fileNames: names)
    }

    public func deleteAll() async throws(StoreError) {
        let names = try await database.write { db in
            let names = try String.fetchAll(
                db,
                sql: "SELECT audioPath FROM dictation WHERE audioPath IS NOT NULL",
            )
            _ = try DictationRecord.deleteAll(db)
            return names
        }
        try audio.remove(fileNames: names)
    }

    public func orphanAudio() async throws(StoreError) -> [URL] {
        let files = audio
        let referenced = try await database.read { db in
            Set(
                try String.fetchAll(
                    db,
                    sql: "SELECT audioPath FROM dictation WHERE audioPath IS NOT NULL",
                )
            )
        }
        return try files.fileNames()
            .filter { !referenced.contains($0) }
            .map { files.directory.appending(path: $0) }
    }

    public func purge(olderThan date: Date) async throws(StoreError) {
        let names = try await database.write { db in
            let expired =
                DictationRecord
                .filter(Column("createdAt") < date)
                .filter(Column("status") != HistoryItem.Status.pending.rawValue)
            let names = try expired.select(Column("audioPath"), as: String?.self).fetchAll(db)
            _ = try expired.deleteAll(db)
            return names.compactMap { $0 }
        }
        try audio.remove(fileNames: names)
    }

    public func expireAudio(olderThan date: Date) async throws(StoreError) {
        let names = try await database.write { db in
            let expired =
                DictationRecord
                .filter(Column("createdAt") < date)
                .filter(Column("status") != HistoryItem.Status.pending.rawValue)
                .filter(Column("audioPath") != nil)
            let names = try expired.select(Column("audioPath"), as: String.self).fetchAll(db)
            try expired.updateAll(db, Column("audioPath").set(to: nil))
            return names
        }
        try audio.remove(fileNames: names)
    }

    public func history(matching query: String, limit: Int) -> AsyncStream<[HistoryItem]> {
        let directory = database.audioDirectory
        let observation = ValueObservation.tracking { db in
            try HistorySearch.records(matching: query, limit: limit, in: db)
        }
        let queue = database.queue
        let (stream, continuation) = AsyncStream.makeStream(
            of: [HistoryItem].self,
            bufferingPolicy: .bufferingNewest(1),
        )
        let task = Task {
            do {
                for try await records in observation.values(in: queue) {
                    continuation.yield(Self.items(from: records, audioDirectory: directory))
                }
            } catch {
                StoreLog.failure("history observation", error)
            }
            continuation.finish()
        }
        continuation.onTermination = { _ in task.cancel() }
        return stream
    }

    private static func items(
        from records: [DictationRecord],
        audioDirectory: URL,
    )
        -> [HistoryItem]
    {
        records.compactMap { record in
            do {
                return try record.item(audioDirectory: audioDirectory)
            } catch {
                StoreLog.skippedRow(record.id)
                return nil
            }
        }
    }

    private func storedRecord(for item: HistoryItem) -> DictationRecord {
        DictationRecord(item, keepsAudio: !discardsAudio(of: item))
    }

    private func discardsAudio(of item: HistoryItem) -> Bool {
        switch item.status {
        case .inserted, .copied: retention() == .off
        case .canceled, .pending, .recovered, .failed, .refused: false
        }
    }

    private func finishWrite(of item: HistoryItem) async throws(StoreError) {
        guard discardsAudio(of: item) else { return }
        if let url = item.audioURL { try audio.remove(url) }
        try await delete(id: item.id)
    }
}
