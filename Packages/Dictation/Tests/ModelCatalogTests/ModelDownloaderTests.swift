import Core
import Foundation
@testable import ModelCatalog
import Testing

internal struct ModelDownloaderTests {
    private let fixtures = DownloadFixtures()

    @Test
    func downloadsVerifiesAndInstallsEveryFile() async throws {
        let config = fixtures.payload(bytes: 300, seed: 1)
        let weights = fixtures.payload(bytes: 20_000, seed: 2)
        let entry = fixtures.makeEntry(files: [
            ("config.json", config), ("sub/model.bin", weights),
        ])
        StubURLProtocol.serve(repo: fixtures.repo) { request in
            .body(request.url?.lastPathComponent == "config.json" ? config : weights)
        }
        let downloader = fixtures.makeDownloader()
        let events = await fixtures.collect(
            downloader.download(entry, allowsConstrainedNetwork: false)
        )
        #expect(events.last == .completed)
        #expect(events.contains(.verifying))
        #expect(downloader.state(of: entry) == .ready)
        let installed = fixtures.storage.directory(of: entry).appending(path: "sub/model.bin")
        #expect(try Data(contentsOf: installed) == weights)
    }

    @Test
    func progressNeverExceedsTotalAndEndsAtTotal() async throws {
        let weights = fixtures.payload(bytes: 50_000)
        let entry = fixtures.makeEntry(files: [("model.bin", weights)])
        StubURLProtocol.serve(repo: fixtures.repo) { _ in .body(weights) }
        let events = await fixtures.collect(
            fixtures.makeDownloader().download(entry, allowsConstrainedNetwork: false)
        )
        let received = events.compactMap { event -> Int? in
            guard case .progress(let bytes, let total) = event, total == 50_000 else { return nil }
            return bytes
        }
        #expect(received.last == 50_000)
        #expect(received == received.sorted())
        #expect(received.allSatisfy { $0 <= 50_000 })
    }

    @Test
    func hashMismatchFailsAndLeavesNothingInstalled() async throws {
        let weights = fixtures.payload(bytes: 4_000)
        let entry = fixtures.makeEntry(
            files: [("model.bin", weights)],
            corruptingDigestOf: "model.bin",
        )
        StubURLProtocol.serve(repo: fixtures.repo) { _ in .body(weights) }
        let downloader = fixtures.makeDownloader()
        let events = await fixtures.collect(
            downloader.download(entry, allowsConstrainedNetwork: false)
        )
        #expect(events.last == .failed(.hashMismatch(path: "model.bin")))
        #expect(downloader.state(of: entry) == .failed(.hashMismatch(path: "model.bin")))
        let destination = fixtures.storage.directory(of: entry).appending(path: "model.bin")
        #expect(!FileManager.default.fileExists(atPath: destination.path()))
        #expect(
            !FileManager.default.fileExists(
                atPath: fixtures.storage.partialURL(entry.files[0], of: entry).path()
            )
        )
    }

    @Test
    func sizeMismatchFailsBeforeHashing() async throws {
        let weights = fixtures.payload(bytes: 4_000)
        let entry = fixtures.makeEntry(files: [("model.bin", weights)])
        StubURLProtocol.serve(repo: fixtures.repo) { _ in .body(weights.prefix(3_000)) }
        let events = await fixtures.collect(
            fixtures.makeDownloader().download(entry, allowsConstrainedNetwork: false)
        )
        #expect(events.last == .failed(.sizeMismatch(path: "model.bin")))
        #expect(!events.contains(.verifying))
    }

    @Test
    func httpErrorBecomesNetworkFailure() async throws {
        let entry = fixtures.makeEntry(files: [("model.bin", fixtures.payload(bytes: 100))])
        StubURLProtocol.serve(repo: fixtures.repo) { _ in .status(404) }
        let events = await fixtures.collect(
            fixtures.makeDownloader().download(entry, allowsConstrainedNetwork: false)
        )
        #expect(events.last == .failed(.networkFailed(code: 404)))
    }

    @Test
    func alreadyInstalledFilesAreNotFetchedAgain() async throws {
        let weights = fixtures.payload(bytes: 5_000)
        let entry = fixtures.makeEntry(files: [("model.bin", weights)])
        let requests = RequestCounter()
        StubURLProtocol.serve(repo: fixtures.repo) { _ in
            requests.increment()
            return .body(weights)
        }
        let downloader = fixtures.makeDownloader()
        _ = await fixtures.collect(downloader.download(entry, allowsConstrainedNetwork: false))
        let events = await fixtures.collect(
            downloader.download(entry, allowsConstrainedNetwork: false)
        )
        #expect(events.last == .completed)
        #expect(requests.count == 1)
    }

    @Test
    func atomicInstallReplacesACorruptedExistingFile() async throws {
        let weights = fixtures.payload(bytes: 5_000)
        let entry = fixtures.makeEntry(files: [("model.bin", weights)])
        StubURLProtocol.serve(repo: fixtures.repo) { _ in .body(weights) }
        let destination = fixtures.storage.directory(of: entry).appending(path: "model.bin")
        try FileManager.default.createDirectory(
            at: destination.deletingLastPathComponent(),
            withIntermediateDirectories: true,
        )
        try Data(repeating: 9, count: 12).write(to: destination)
        let events = await fixtures.collect(
            fixtures.makeDownloader().download(entry, allowsConstrainedNetwork: false)
        )
        #expect(events.last == .completed)
        #expect(try Data(contentsOf: destination) == weights)
    }

    @Test
    func installedModelsAreExcludedFromBackup() async throws {
        let weights = fixtures.payload(bytes: 1_000)
        let entry = fixtures.makeEntry(files: [("model.bin", weights)])
        StubURLProtocol.serve(repo: fixtures.repo) { _ in .body(weights) }
        _ = await fixtures.collect(
            fixtures.makeDownloader().download(entry, allowsConstrainedNetwork: false)
        )
        let values = try fixtures.storage.root.resourceValues(forKeys: [.isExcludedFromBackupKey])
        #expect(values.isExcludedFromBackup == true)
    }
}
