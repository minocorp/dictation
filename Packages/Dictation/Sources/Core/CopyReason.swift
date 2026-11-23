public enum CopyReason: String, Hashable, Sendable {
    case targetLostFocus
    case noTextField
    case modifiersHeld
    case composingTimeout
    case allMethodsFailed
}
