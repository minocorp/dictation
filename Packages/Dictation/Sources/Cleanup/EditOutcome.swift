public enum EditOutcome: Equatable, Sendable {
    case edited(String)
    case unchanged(CleanupFallbackReason)
}
