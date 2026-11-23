internal enum ModelOutcome: Sendable {
    case text(String)
    case fallback(CleanupFallbackReason)
}
