public enum OutputTag: Hashable, Sendable {
    case cleaned
    case edited

    var opening: String {
        switch self {
        case .cleaned: "<cleaned>"
        case .edited: "<edited>"
        }
    }

    var closing: String {
        switch self {
        case .cleaned: "</cleaned>"
        case .edited: "</edited>"
        }
    }
}
