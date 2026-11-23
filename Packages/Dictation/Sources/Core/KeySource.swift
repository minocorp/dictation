public protocol KeySource: Sendable {
    var events: AsyncStream<RawKeyEvent> { get }

    func start() throws(HotkeyError)
    func stop()
    func setPolicy(_ policy: TapPolicy)
}
