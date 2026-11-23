internal enum Verdict: Equatable, Sendable {
    case noSpeech
    case failed(Failure)
    case text(String)
}
