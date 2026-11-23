public import Core
public import Foundation
import GRDB

public final class HistoryDatabase: Sendable {
    let queue: DatabaseQueue
    let audioDirectory: URL

    public init(directory: URL) throws(StoreError) {
        let layout = DataDirectory(root: directory)
        try layout.prepare()
        do {
            queue = try DatabaseQueue(path: layout.databaseFile.path(percentEncoded: false))
            try HistoryMigrations.migrator.migrate(queue)
        } catch {
            throw .make(error, access: .write)
        }
        audioDirectory = layout.audio
    }

    public init(inMemoryWithAudioDirectory audioDirectory: URL) throws(StoreError) {
        do {
            queue = try DatabaseQueue()
            try HistoryMigrations.migrator.migrate(queue)
            try FileManager.default.createDirectory(
                at: audioDirectory,
                withIntermediateDirectories: true,
            )
        } catch {
            throw .make(error, access: .write)
        }
        self.audioDirectory = audioDirectory
    }

    func read<T: Sendable>(
        _ body: @Sendable (Database) throws -> T
    ) async throws(StoreError) -> T {
        do {
            return try await queue.read(body)
        } catch {
            throw .make(error, access: .read)
        }
    }

    func write<T: Sendable>(
        _ body: @Sendable (Database) throws -> T
    ) async throws(StoreError) -> T {
        do {
            return try await queue.write(body)
        } catch {
            throw .make(error, access: .write)
        }
    }
}
