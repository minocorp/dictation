internal struct Active: Equatable, Sendable {
    var pending: Pending
    var mode: Mode
    var phase: Phase
    var elapsed: Duration
    var silent: Duration
    var hasPassedTapThreshold: Bool
    var isCaptureOpen: Bool
    var hasReleased: Bool

    init(pending: Pending, mode: Mode) {
        self.pending = pending
        self.mode = mode
        phase = .capturing
        elapsed = .zero
        silent = .zero
        hasPassedTapThreshold = false
        isCaptureOpen = false
        hasReleased = false
    }
}
