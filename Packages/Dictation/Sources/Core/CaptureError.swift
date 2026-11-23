public enum CaptureError: CancellableError {
    case cancelled
    case permissionDenied
    case noInputDevice
    case deviceUnavailable
    case alreadyRunning
    case engineFailed(code: Int)
    case diskWriteFailed(code: Int)
}
