public import Core

public enum CleanupFallbackReason: Equatable, Sendable {
    case timedOut
    case engine(CleanupError)
    case guardFailed(GuardFailure)
}
