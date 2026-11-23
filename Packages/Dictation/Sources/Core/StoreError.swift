public enum StoreError: CancellableError {
    case cancelled
    case notFound
    case readFailed(code: Int)
    case writeFailed(code: Int)
    case fileFailed(code: Int)
}
