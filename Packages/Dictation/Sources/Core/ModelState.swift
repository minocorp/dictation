public enum ModelState: Equatable, Sendable {
    case notDownloaded
    case waitingForApproval
    case downloading(bytesReceived: Int, totalBytes: Int)
    case ready
    case failed(ModelError)
}
