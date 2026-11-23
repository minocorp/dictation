public enum DiagnosticsError: CancellableError {
    case cancelled
    case exportFailed(code: Int)
}
