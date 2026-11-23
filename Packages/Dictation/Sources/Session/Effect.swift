import Core
import Foundation

internal enum Effect: Equatable, Sendable {
    case startCapture(DictationID, device: InputDevice)
    case stopCapture(DictationID)
    case discardCapture(DictationID)
    case discardAudio(URL)
    case cancelWork(DictationID)
    case readAudio(DictationID, URL)
    case readFocus(DictationID)
    case readSelection(DictationID)
    case transcribe(Segment, languages: [Locale])
    case clean(DictationID, index: Int, input: CleanInput)
    case edit(DictationID, selection: String, instruction: String)
    case insert(DictationID, text: String, focus: FocusSnapshot)
    case copy(String)
    case save(HistoryItem)
    case update(HistoryItem)
    case play(Sound)
    case startTimer(SessionTimer, Duration)
    case cancelTimer(SessionTimer)
    case setTapPolicy(TapPolicy)
    case observeForLearning(text: String, focus: FocusSnapshot)
}
