import Core

internal enum Failure: Equatable, Sendable {
    case capture(CaptureError)
    case speech(SpeechError)
    case cleanup(CleanupError)
    case store(StoreError)
    case hotkey(HotkeyError)
    case selection(Selection)
    case insert(InsertOutcome)
}
