public import Core

public struct ModelActions: Sendable {
    let downloadAllowingConstrained: @Sendable (ModelEntry) -> AsyncStream<DownloadEvent>
    let cancelDownload: @Sendable (ModelEntry) -> Void
    let delete: @Sendable (ModelEntry) throws(ModelError) -> Void
    let deleteEverything: @MainActor @Sendable () async -> Void

    public init(
        downloadAllowingConstrained: @escaping @Sendable (ModelEntry) -> AsyncStream<DownloadEvent>,
        cancelDownload: @escaping @Sendable (ModelEntry) -> Void,
        delete: @escaping @Sendable (ModelEntry) throws(ModelError) -> Void,
        deleteEverything: @escaping @MainActor @Sendable () async -> Void,
    ) {
        self.downloadAllowingConstrained = downloadAllowingConstrained
        self.cancelDownload = cancelDownload
        self.delete = delete
        self.deleteEverything = deleteEverything
    }
}
