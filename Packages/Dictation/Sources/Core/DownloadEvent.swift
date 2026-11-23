public enum DownloadEvent: Equatable, Sendable {
    case progress(bytesReceived: Int, totalBytes: Int)
    case waitingForApproval
    case verifying
    case completed
    case failed(ModelError)
}
