public enum CleanupSource: Equatable, Sendable {
    case disabled
    case gateSkipped
    case model
    case fallback(CleanupFallbackReason)
}
