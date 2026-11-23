import Core
import Foundation
@testable import ModelCatalog
import Testing

internal struct ModelStorageTests {
    private let fixtures = DownloadFixtures()

    private func installedLibrary(
        weights: Data
    ) async throws -> (ManifestModelLibrary, ModelEntry) {
        let entry = fixtures.makeEntry(files: [("model.bin", weights)])
        StubURLProtocol.serve(repo: fixtures.repo) { _ in .body(weights) }
        let library = ManifestModelLibrary(
            manifest: ModelManifest(schemaVersion: 1, models: [entry]),
            profile: MachineProfile(ramGB: 16, languages: []),
            storage: fixtures.storage,
            downloader: fixtures.makeDownloader(),
        )
        let events = await fixtures.collect(library.download(entry))
        try #require(events.last == .completed)
        return (library, entry)
    }

    @Test
    func loadTimeVerificationAcceptsAnIntactModel() async throws {
        let (library, entry) = try await installedLibrary(weights: fixtures.payload(bytes: 3_000))
        let directory = try await library.verifiedDirectory(of: entry)
        #expect(directory == fixtures.storage.directory(of: entry))
        #expect(await library.state(of: entry) == .ready)
    }

    @Test
    func loadTimeVerificationDeletesAFileWithTheWrongContent() async throws {
        let weights = fixtures.payload(bytes: 3_000)
        let (library, entry) = try await installedLibrary(weights: weights)
        let file = fixtures.storage.directory(of: entry).appending(path: "model.bin")
        var tampered = weights
        tampered[0] ^= 0xFF
        try tampered.write(to: file)
        await #expect(throws: ModelError.hashMismatch(path: "model.bin")) {
            try await library.verifiedDirectory(of: entry)
        }
        #expect(!FileManager.default.fileExists(atPath: file.path()))
        #expect(await library.state(of: entry) == .notDownloaded)
    }

    @Test
    func loadTimeVerificationRejectsATruncatedFile() async throws {
        let weights = fixtures.payload(bytes: 3_000)
        let (library, entry) = try await installedLibrary(weights: weights)
        let file = fixtures.storage.directory(of: entry).appending(path: "model.bin")
        try weights.prefix(100).write(to: file)
        #expect(await library.state(of: entry) == .notDownloaded)
        await #expect(throws: ModelError.loadFailed) {
            try await library.verifiedDirectory(of: entry)
        }
    }

    @Test
    func builtInEntriesAreAlwaysReady() async {
        let library = ManifestModelLibrary(
            manifest: ModelManifest(schemaVersion: 1, models: []),
            profile: MachineProfile(ramGB: 8, languages: []),
            storage: fixtures.storage,
            downloader: fixtures.makeDownloader(),
        )
        #expect(await library.state(of: .appleSpeechAnalyzer) == .ready)
        #expect(await library.state(of: .appleFoundationModels) == .ready)
    }

    @Test
    func downloadOfAnEntryOutsideTheManifestFails() async {
        let library = ManifestModelLibrary(
            manifest: ModelManifest(schemaVersion: 1, models: []),
            profile: MachineProfile(ramGB: 16, languages: []),
            storage: fixtures.storage,
            downloader: fixtures.makeDownloader(),
        )
        let events = await fixtures.collect(library.download(ManifestFixtures.entry()))
        #expect(events == [.failed(.unknownModel)])
    }

    @Test
    func deleteRemovesInstalledFiles() async throws {
        let (library, entry) = try await installedLibrary(weights: fixtures.payload(bytes: 2_000))
        try library.delete(entry)
        #expect(await library.state(of: entry) == .notDownloaded)
    }

    @Test
    func unchangedFileIsNotHashedAgain() async throws {
        let weights = fixtures.payload(bytes: 3_000)
        let (library, entry) = try await installedLibrary(weights: weights)
        let file = fixtures.storage.directory(of: entry).appending(path: "model.bin")
        let fixedDate = Date(timeIntervalSince1970: 1_000_000)
        try FileManager.default.setAttributes(
            [.modificationDate: fixedDate],
            ofItemAtPath: file.path(),
        )
        _ = try await library.verifiedDirectory(of: entry)
        var sameSizeOtherContent = weights
        sameSizeOtherContent[0] ^= 0xFF
        try sameSizeOtherContent.write(to: file)
        try FileManager.default.setAttributes(
            [.modificationDate: fixedDate],
            ofItemAtPath: file.path(),
        )
        _ = try await library.verifiedDirectory(of: entry)
    }

    @Test
    func changedTimestampForcesAFreshHash() async throws {
        let weights = fixtures.payload(bytes: 3_000)
        let (library, entry) = try await installedLibrary(weights: weights)
        let file = fixtures.storage.directory(of: entry).appending(path: "model.bin")
        try FileManager.default.setAttributes(
            [.modificationDate: Date(timeIntervalSince1970: 1)],
            ofItemAtPath: file.path(),
        )
        _ = try await library.verifiedDirectory(of: entry)
        var tampered = weights
        tampered[1] ^= 0xFF
        try tampered.write(to: file)
        await #expect(throws: ModelError.hashMismatch(path: "model.bin")) {
            try await library.verifiedDirectory(of: entry)
        }
    }
}
