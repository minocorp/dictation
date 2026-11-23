import Core

internal struct InsertionWaits: Sendable {
    enum Focus: Equatable, Sendable {
        case ready(FocusSnapshot?)
        case secure
        case targetChanged
        case composingTimeout
    }

    let modifiers: any ModifierState
    let focusReader: any FocusReader
    let clock: any Clock<Duration>

    func modifiersReleased() async -> Bool {
        let polls = InsertionTiming.polls(
            in: InsertionTiming.modifierWait,
            every: InsertionTiming.modifierPoll,
        )
        for _ in 0..<polls {
            if modifiers.heldModifiers().isEmpty { return true }
            guard await clock.sleepUnlessCancelled(for: InsertionTiming.modifierPoll) else {
                return false
            }
        }
        return modifiers.heldModifiers().isEmpty
    }

    func settledFocus(pid: Int32) async -> Focus {
        let polls = InsertionTiming.polls(
            in: InsertionTiming.composingWait,
            every: InsertionTiming.composingPoll,
        )
        for _ in 0...polls {
            guard let live = await focusReader.snapshot() else { return .ready(nil) }
            if live.target.pid != pid { return .targetChanged }
            if live.isSecure { return .secure }
            if !live.isComposing { return .ready(live) }
            guard await clock.sleepUnlessCancelled(for: InsertionTiming.composingPoll) else {
                return .composingTimeout
            }
        }
        return .composingTimeout
    }
}
