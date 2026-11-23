internal protocol InputMethodProbe: Sendable {
    func isInputMethodActive() async -> Bool
}
