public import Core

internal enum ModelDownloadNote: Equatable {
    case none
    case downloading(DownloadProgress, totalBytes: Int)
    case waitingForApproval
    case failed(ModelError)
    case ready
}
