import Core

internal enum KeyCaptureOutcome: Equatable {
    case accepted(KeyBinding)
    case cancelled
    case ignored
}
