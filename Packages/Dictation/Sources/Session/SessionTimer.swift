internal enum SessionTimer: Hashable, Sendable {
    case tapThreshold
    case doubleTapWindow
    case handsFreeSecond
    case processingDelay
    case hudExpiry
}
