public enum SpeechError: CancellableError {
    case cancelled
    case modelUnavailable
    case unsupportedLanguage
    case failed(code: Int)
}
