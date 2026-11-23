package protocol KeyboardLayoutSource: Sendable {
    func currentLayout() async -> (any KeyTranslating)?
}
