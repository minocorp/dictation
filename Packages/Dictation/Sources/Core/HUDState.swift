public enum HUDState: Equatable, Sendable {
    case hidden
    case listening
    case handsFree(elapsed: Duration, countdown: Duration?)
    case editing
    case processing
    case copied
    case canceled
    case saved
    case noSpeech
    case problem(Problem)
}
