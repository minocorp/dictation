public enum Selection: Hashable, Sendable {
    case text(String)
    case none
    case tooLong
    case unreadable
}
