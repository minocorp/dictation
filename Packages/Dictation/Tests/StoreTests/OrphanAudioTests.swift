import Core
import Foundation
@testable import Store
import Testing

internal struct OrphanAudioTests {
    private let fixtures = HistoryFixtures()

    @Test
    func recordingWithoutRowIsOrphan() async throws {
        let store = GRDBHistoryStore(
            database: try fixtures.makeDatabase(),
            retention: { .thirtyDays },
        )
        let orphan = try fixtures.writeAudio(named: "lost")
        let kept = try fixtures.writeAudio(named: "kept")
        try await store.save(fixtures.item(audioURL: kept, status: .pending))
        #expect(try await store.orphanAudio() == [orphan])
    }

    @Test
    func nonCAFFilesAreIgnored() async throws {
        let store = GRDBHistoryStore(
            database: try fixtures.makeDatabase(),
            retention: { .thirtyDays },
        )
        _ = try fixtures.writeAudio(named: "keep")
        try Data().write(to: fixtures.audioDirectory.appending(path: "notes.txt"))
        #expect(try await store.orphanAudio().map(\.lastPathComponent) == ["keep.caf"])
    }

    @Test
    func missingAudioDirectoryHasNoOrphans() async throws {
        let store = GRDBHistoryStore(
            database: try fixtures.makeDatabase(),
            retention: { .thirtyDays },
        )
        try FileManager.default.removeItem(at: fixtures.audioDirectory)
        #expect(try await store.orphanAudio().isEmpty)
    }
}
