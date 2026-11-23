internal protocol TapProbe: Sendable {
    func read() -> TapHealth
}
