import Core
import CoreTesting
import Testing
@testable import UI

@MainActor
internal struct ModelDownloadsTests {
    private final class Readiness {
        var stages: [ModelStage] = []
    }

    private let speech = UIFixtures.entry(id: "speech-a", stage: .speech, bytes: 1_000)
    private let cleanup = UIFixtures.entry(id: "cleanup-a", stage: .cleanup, bytes: 3_000)
    private let readiness = Readiness()

    private func makeLibrary() -> FakeModelLibrary {
        FakeModelLibrary(
            recommended: (speech: speech, cleanup: cleanup),
            entries: [.appleSpeechAnalyzer, speech, .appleFoundationModels, cleanup],
        )
    }

    private func makeDownloads(_ library: FakeModelLibrary) -> ModelDownloads {
        let readiness = readiness
        return ModelDownloads(
            library: library,
            actions: ModelActions(
                downloadAllowingConstrained: { _ in AsyncStream { $0.finish() } },
                cancelDownload: { _ in },
                delete: { _ in },
                deleteEverything: {},
            ),
            didBecomeReady: { readiness.stages.append($0) },
        )
    }

    private func settle(_ downloads: ModelDownloads, _ entry: ModelEntry) async {
        for _ in 0..<1_000 {
            guard case .downloading = downloads.state(of: entry) else {
                return
            }
            await Task.yield()
        }
    }

    @Test
    func builtInEntriesAreAlwaysReady() {
        let downloads = makeDownloads(makeLibrary())
        #expect(downloads.state(of: .appleSpeechAnalyzer) == .ready)
    }

    @Test
    func refreshReadsLibraryStates() async {
        let library = makeLibrary()
        library.setState(.ready, of: speech)
        let downloads = makeDownloads(library)
        await downloads.refresh()
        #expect(downloads.state(of: speech) == .ready)
        #expect(downloads.state(of: cleanup) == .notDownloaded)
    }

    @Test
    func completedDownloadMarksReadyAndNotifiesTheStage() async {
        let library = makeLibrary()
        library.setDownloadScript(
            [.progress(bytesReceived: 500, totalBytes: 1_000), .verifying, .completed],
            for: speech,
        )
        let downloads = makeDownloads(library)
        downloads.download(speech)
        await settle(downloads, speech)
        #expect(downloads.state(of: speech) == .ready)
        #expect(readiness.stages == [.speech])
        #expect(library.downloadRequests == ["speech-a"])
    }

    @Test
    func failedDownloadKeepsTheError() async {
        let library = makeLibrary()
        library.setDownloadScript([.failed(.networkFailed(code: -1009))], for: speech)
        let downloads = makeDownloads(library)
        downloads.download(speech)
        await settle(downloads, speech)
        #expect(downloads.state(of: speech) == .failed(.networkFailed(code: -1009)))
        #expect(readiness.stages.isEmpty)
    }

    @Test
    func waitingForApprovalIsKept() async {
        let library = makeLibrary()
        library.setDownloadScript([.waitingForApproval], for: speech)
        let downloads = makeDownloads(library)
        downloads.download(speech)
        await settle(downloads, speech)
        #expect(downloads.state(of: speech) == .waitingForApproval)
    }

    @Test
    func progressAggregatesActiveDownloads() {
        let downloads = makeDownloads(makeLibrary())
        #expect(downloads.progress(of: [speech, cleanup]) == nil)
    }
}
