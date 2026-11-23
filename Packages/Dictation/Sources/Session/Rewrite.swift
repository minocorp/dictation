import Core

internal enum Rewrite: Equatable, Sendable {
    case notStarted
    case running
    case done(Result<String, CleanupError>)
}
