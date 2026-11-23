import Core
import Foundation

internal enum InputEvent: Equatable, Sendable {
    case started
    case focus(FocusSnapshot?)
    case selection(Selection)
    case segment(Segment)
    case segmentsEnded
    case finished(audioURL: URL?)
}
