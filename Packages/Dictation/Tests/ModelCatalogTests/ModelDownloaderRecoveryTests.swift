import Core
import Foundation
@testable import ModelCatalog
import Testing

internal struct ModelDownloaderRecoveryTests {
    private let fixtures = DownloadFixtures()

    @Test
    func insufficientDiskSpaceFailsBeforeAnyRequest() async throws {
        let weights = fixtures.payload(bytes: 10_000)
        let entry = fixtures.makeEntry(files: [("model.bin", weights)])
        let requests = RequestCounter()
        StubURLProtocol.serve(repo: fixtures.repo) { _ in
            requests.increment()
            return .body(weights)
        }
        let events = await fixtures.collect(
            fixtures.makeDownloader(availableBytes: 9_999)
                .download(entry, allowsConstrainedNetwork: false)
        )
        let needed = ModelDownloader.requiredBytes(withMarginFor: 10_000)
        #expect(events.last == .failed(.insufficientDiskSpace(requiredBytes: needed)))
        #expect(!requests.hasRequests)
    }

    @Test
    func freeSpaceWithoutTheSafetyMarginIsNotEnough() async throws {
        let weights = fixtures.payload(bytes: 10_000)
        let entry = fixtures.makeEntry(files: [("model.bin", weights)])
        StubURLProtocol.serve(repo: fixtures.repo) { _ in .body(weights) }
        let events = await fixtures.collect(
            fixtures.makeDownloader(availableBytes: 10_000)
                .download(entry, allowsConstrainedNetwork: false)
        )
        #expect(events.last?.isFailure == true)
    }

    @Test
    func unknownFreeSpaceDoesNotBlockTheDownload() async throws {
        let weights = fixtures.payload(bytes: 1_000)
        let entry = fixtures.makeEntry(files: [("model.bin", weights)])
        StubURLProtocol.serve(repo: fixtures.repo) { _ in .body(weights) }
        let events = await fixtures.collect(
            fixtures.makeDownloader(availableBytes: nil)
                .download(entry, allowsConstrainedNetwork: false)
        )
        #expect(events.last == .completed)
    }

    @Test
    func outOfSpaceDuringTransferIsNotReportedAsNetworkFailure() async throws {
        let weights = fixtures.payload(bytes: 1_000)
        let entry = fixtures.makeEntry(files: [("model.bin", weights)])
        let outOfSpace = NSError(domain: NSPOSIXErrorDomain, code: Int(ENOSPC))
        StubURLProtocol.serve(repo: fixtures.repo) { _ in
            .failure(
                URLError(.cannotWriteToFile, userInfo: [NSUnderlyingErrorKey: outOfSpace])
            )
        }
        let events = await fixtures.collect(
            fixtures.makeDownloader().download(entry, allowsConstrainedNetwork: false)
        )
        #expect(events.last == .failed(.insufficientDiskSpace(requiredBytes: 1_000)))
    }

    @Test
    func newDownloadWaitsForTheOldOneAndKeepsItsState() async throws {
        let weights = fixtures.payload(bytes: 200_000)
        let entry = fixtures.makeEntry(files: [("model.bin", weights)])
        let ranges = RangeLog()
        StubURLProtocol.serve(repo: fixtures.repo) { request in
            ranges.record(request.value(forHTTPHeaderField: "Range"))
            return ranges.count == 1 ? .stalled(weights, deliveredBytes: 80_000) : .body(weights)
        }
        let downloader = fixtures.makeDownloader()
        var first = downloader.download(entry, allowsConstrainedNetwork: false).makeAsyncIterator()
        while let event = await first.next() {
            if case .progress(let bytes, _) = event, bytes >= 60_000 { break }
        }
        let second = downloader.download(entry, allowsConstrainedNetwork: false)
        var firstTail: [DownloadEvent] = []
        while let event = await first.next() { firstTail.append(event) }
        let secondEvents = await fixtures.collect(second)
        #expect(firstTail.last == .failed(.cancelled))
        #expect(secondEvents.last == .completed)
        #expect(downloader.state(of: entry) == .ready)
    }

    @Test
    func deleteAfterTransferStopsLeavesNoPartialFiles() async throws {
        let weights = fixtures.payload(bytes: 200_000)
        let entry = fixtures.makeEntry(files: [("model.bin", weights)])
        StubURLProtocol.serve(repo: fixtures.repo) { _ in
            .stalled(weights, deliveredBytes: 80_000)
        }
        let downloader = fixtures.makeDownloader()
        var events = downloader.download(entry, allowsConstrainedNetwork: false)
            .makeAsyncIterator()
        while let event = await events.next() {
            if case .progress(let bytes, _) = event, bytes >= 60_000 { break }
        }
        try await downloader.deleteFilesAfterTransferStops(of: entry)
        #expect(downloader.state(of: entry) == .notDownloaded)
        let partials = fixtures.storage.partialRoot.appending(path: entry.id)
        #expect(!FileManager.default.fileExists(atPath: partials.path()))
    }

    @Test
    func constrainedNetworkWaitsForApprovalThenUsesTheUnconstrainedSession() async throws {
        let weights = fixtures.payload(bytes: 3_000)
        let entry = fixtures.makeEntry(files: [("model.bin", weights)])
        StubURLProtocol.serve(repo: fixtures.repo) { request in
            guard request.value(forHTTPHeaderField: DownloadFixtures.constrainedHeader) == "true"
            else {
                return .failure(
                    URLError(
                        .notConnectedToInternet,
                        userInfo: [
                            NSURLErrorNetworkUnavailableReasonKey:
                                URLError.NetworkUnavailableReason.constrained.rawValue
                        ],
                    )
                )
            }
            return .body(weights)
        }
        let downloader = fixtures.makeDownloader()
        let first = await fixtures.collect(
            downloader.download(entry, allowsConstrainedNetwork: false)
        )
        #expect(first.last == .waitingForApproval)
        #expect(downloader.state(of: entry) == .waitingForApproval)
        let second = await fixtures.collect(
            downloader.download(entry, allowsConstrainedNetwork: true)
        )
        #expect(second.last == .completed)
    }

    @Test
    func cancelledDownloadResumesFromTheReceivedBytes() async throws {
        let weights = fixtures.payload(bytes: 200_000)
        let entry = fixtures.makeEntry(files: [("model.bin", weights)])
        let ranges = RangeLog()
        StubURLProtocol.serve(repo: fixtures.repo) { request in
            ranges.record(request.value(forHTTPHeaderField: "Range"))
            return ranges.count == 1 ? .stalled(weights, deliveredBytes: 80_000) : .body(weights)
        }
        let downloader = fixtures.makeDownloader()
        var first = downloader.download(entry, allowsConstrainedNetwork: false).makeAsyncIterator()
        while let event = await first.next() {
            if case .progress(let bytes, _) = event, bytes >= 60_000 { break }
        }
        downloader.cancelDownload(of: entry)
        while await first.next() != nil {}
        #expect(
            FileManager.default.fileExists(
                atPath: fixtures.storage.resumeURL(entry.files[0], of: entry).path()
            )
        )
        let second = await fixtures.collect(
            downloader.download(entry, allowsConstrainedNetwork: false)
        )
        #expect(second.last == .completed)
        #expect(ranges.values.last??.hasPrefix("bytes=") == true)
        let installed = fixtures.storage.directory(of: entry).appending(path: "model.bin")
        #expect(try Data(contentsOf: installed) == weights)
    }

    @Test
    func entryWithoutRevisionIsUnknown() async throws {
        let entry = fixtures.makeEntry(files: [("model.bin", Data([1]))])
        let unpinned = ModelEntry(
            id: entry.id,
            stage: entry.stage,
            displayName: entry.displayName,
            family: entry.family,
            repo: entry.repo,
            revision: nil,
            observedRevision: nil,
            format: entry.format,
            quant: entry.quant,
            license: entry.license,
            licenseVerified: true,
            languages: entry.languages,
            minRAMGB: 8,
            downloadBytes: 1,
            files: entry.files,
            defaultFor: [],
            runtime: nil,
            verified: [],
            unverified: nil,
        )
        let events = await fixtures.collect(
            fixtures.makeDownloader().download(unpinned, allowsConstrainedNetwork: false)
        )
        #expect(events.last == .failed(.unknownModel))
    }
}

extension DownloadEvent {
    fileprivate var isFailure: Bool {
        if case .failed = self { return true }
        return false
    }
}
