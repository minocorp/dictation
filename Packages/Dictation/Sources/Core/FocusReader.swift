public protocol FocusReader: Sendable {
    func snapshot() async -> FocusSnapshot?
    func selection(maxCharacters: Int) async -> Selection
}
