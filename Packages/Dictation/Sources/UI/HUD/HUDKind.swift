import Core

internal enum HUDKind: Hashable {
    case hidden
    case listening
    case handsFree
    case editing
    case processing
    case copied
    case canceled
    case saved
    case noSpeech
    case problem
}

extension HUDState {
    var kind: HUDKind {
        switch self {
        case .hidden: .hidden
        case .listening: .listening
        case .handsFree: .handsFree
        case .editing: .editing
        case .processing: .processing
        case .copied: .copied
        case .canceled: .canceled
        case .saved: .saved
        case .noSpeech: .noSpeech
        case .problem: .problem
        }
    }
}
