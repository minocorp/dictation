import Core

internal enum ResultEvent: Equatable, Sendable {
    case transcribed(index: Int, result: Result<String, SpeechError>)
    case cleaned(index: Int, result: Result<String, CleanupError>)
    case edited(Result<String, CleanupError>)
    case inserted(InsertOutcome)
    case failed(Failure)
}
