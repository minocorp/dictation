import Foundation

public enum GlobeAdvice: Hashable, Sendable {
    case none
    case changesInputSource
    case showsEmoji
    case startsDictation
    case other

    var message: LocalizedStringResource? {
        switch self {
        case .none: nil
        case .changesInputSource: UIString.keyGlobeChangesInputSource
        case .showsEmoji: UIString.keyGlobeShowsEmoji
        case .startsDictation: UIString.keyGlobeStartsDictation
        case .other: UIString.keyGlobeOther
        }
    }
}
