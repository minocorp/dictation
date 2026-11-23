public import Core
public import Foundation

public final class ManifestModelLibrary: ModelLibrary {
    private let manifest: ModelManifest
    private let profile: MachineProfile
    private let storage: ModelStorage
    private let downloader: ModelDownloader

    public init(
        manifest: ModelManifest,
        profile: MachineProfile,
        storage: ModelStorage,
        downloader: ModelDownloader,
    ) {
        self.manifest = manifest
        self.profile = profile
        self.storage = storage
        self.downloader = downloader
    }

    public func recommended() -> (speech: ModelEntry, cleanup: ModelEntry) {
        ModelRecommendation.pick(from: manifest.models, profile: profile)
    }

    public func entries(stage: ModelStage) -> [ModelEntry] {
        let builtIn: ModelEntry =
            switch stage {
            case .speech: .appleSpeechAnalyzer
            case .cleanup: .appleFoundationModels
            }
        return [builtIn] + manifest.entries(stage: stage)
    }

    public func state(of entry: ModelEntry) async -> ModelState {
        guard entry.isDownloadable else { return .ready }
        guard let known = manifest.entry(id: entry.id) else { return .notDownloaded }
        return downloader.state(of: known)
    }

    public func download(_ entry: ModelEntry) -> AsyncStream<DownloadEvent> {
        startDownload(entry, allowsConstrainedNetwork: false)
    }

    public func downloadAllowingConstrainedNetwork(
        _ entry: ModelEntry
    ) -> AsyncStream<DownloadEvent> {
        startDownload(entry, allowsConstrainedNetwork: true)
    }

    public func cancelDownload(of entry: ModelEntry) {
        guard let known = manifest.entry(id: entry.id) else { return }
        downloader.cancelDownload(of: known)
    }

    public func delete(_ entry: ModelEntry) throws(ModelError) {
        guard let known = manifest.entry(id: entry.id) else { throw .unknownModel }
        try downloader.deleteFiles(of: known)
    }

    public func deleteAfterTransferStops(_ entry: ModelEntry) async throws(ModelError) {
        guard let known = manifest.entry(id: entry.id) else { throw .unknownModel }
        try await downloader.deleteFilesAfterTransferStops(of: known)
    }

    public func verifiedDirectory(of entry: ModelEntry) async throws(ModelError) -> URL {
        guard let known = manifest.entry(id: entry.id), known.isDownloadable else {
            throw .unknownModel
        }
        guard storage.isInstalled(known) else { throw .loadFailed }
        try storage.verify(known)
        return storage.directory(of: known)
    }

    private func startDownload(
        _ entry: ModelEntry,
        allowsConstrainedNetwork: Bool,
    ) -> AsyncStream<DownloadEvent> {
        guard let known = manifest.entry(id: entry.id) else {
            return AsyncStream { continuation in
                continuation.yield(.failed(.unknownModel))
                continuation.finish()
            }
        }
        return downloader.download(known, allowsConstrainedNetwork: allowsConstrainedNetwork)
    }
}
