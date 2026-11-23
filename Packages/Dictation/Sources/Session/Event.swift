import Core

internal enum Event: Equatable, Sendable {
    case gesture(Gesture, Stamp)
    case input(DictationID, InputEvent)
    case result(DictationID, ResultEvent)
    case timer(SessionTimer)
    case system(SystemEvent)
    case request(Request)
}
