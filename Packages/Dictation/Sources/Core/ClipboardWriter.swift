public protocol ClipboardWriter: Sendable {
    func copyTransient(_ text: String) async
}
