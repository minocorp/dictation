import Core

extension CaptureError {
    var diagnosticCode: Int {
        switch self {
        case .cancelled, .permissionDenied, .noInputDevice, .deviceUnavailable, .alreadyRunning:
            0
        case .engineFailed(let code), .diskWriteFailed(let code):
            code
        }
    }
}
