public struct MenuEntry: Equatable, Sendable {
    public enum Kind: Equatable, Sendable {
        case item(MenuAction)
        case label
        case separator
    }

    public let kind: Kind
    public let title: String
    public let isEnabled: Bool
}
