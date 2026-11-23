package enum ClipboardShortcut: Hashable, Sendable {
    case copy
    case paste

    package var character: String {
        switch self {
        case .copy: "c"
        case .paste: "v"
        }
    }

    package var ansiKeyCode: UInt16 {
        switch self {
        case .copy: 8
        case .paste: 9
        }
    }
}
