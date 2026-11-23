public enum ModelError: CancellableError {
    case cancelled
    case unknownModel
    case insufficientDiskSpace(requiredBytes: Int)
    case networkFailed(code: Int)
    case sizeMismatch(path: String)
    case hashMismatch(path: String)
    case fileFailed(code: Int)
    case loadFailed
}
