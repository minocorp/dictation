public import Core

public struct GestureState: Hashable, Sendable {
    enum Phase: Hashable, Sendable {
        case idle
        case pressing(since: ContinuousClock.Instant, isEdit: Bool)
        case tapped(releasedAt: ContinuousClock.Instant)
        case handsFreePressing
        case handsFree
        case endingPress
    }

    public var dictateKey: KeyBinding
    public var pasteLast: KeyBinding
    var phase = Phase.idle
    var isPasteLastDown = false

    public init(dictateKey: KeyBinding, pasteLast: KeyBinding) {
        self.dictateKey = dictateKey
        self.pasteLast = pasteLast
    }

    public var isIdle: Bool { phase == .idle }

    public mutating func reset() {
        phase = .idle
        isPasteLastDown = false
    }
}
