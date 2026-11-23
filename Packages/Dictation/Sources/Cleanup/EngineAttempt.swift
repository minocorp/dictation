import Core

internal enum EngineAttempt: Sendable {
    case output(String)
    case timedOut
    case failed(CleanupError)
}
