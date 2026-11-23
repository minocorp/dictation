public enum CleanupError: CancellableError {
    case cancelled
    case modelUnavailable
    case timedOut
    case rejected
    case failed(code: Int)
}
