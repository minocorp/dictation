internal protocol UnicodeTyper: Sendable {
    func type(_ text: String) -> Bool
}
