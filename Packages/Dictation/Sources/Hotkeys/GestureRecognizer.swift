public import Core

public enum GestureRecognizer {
    public static func recognize(
        _ state: inout GestureState,
        _ event: RawKeyEvent,
        at instant: ContinuousClock.Instant,
    ) -> [Gesture] {
        if event.trigger == .globe, state.dictateKey.trigger != .globe { return [] }
        if state.dictateKey.isShortcutKey(event) {
            return abandonHold(&state) + recognizeShortcutKey(&state, event)
        }
        if event.trigger == .escape { return recognizeEscape(&state, event, at: instant) }
        if event.trigger == state.pasteLast.trigger { return recognizePasteLast(&state, event) }
        if event.trigger == state.dictateKey.trigger {
            return switch event.phase {
            case .pressed: recognizePress(&state, event, at: instant)
            case .released: recognizeRelease(&state, at: instant)
            }
        }
        return []
    }

    private static func abandonHold(_ state: inout GestureState) -> [Gesture] {
        switch state.phase {
        case .pressing, .handsFreePressing:
            state.phase = .idle
            return [.abandon]
        case .idle, .tapped, .handsFree, .endingPress:
            return []
        }
    }

    private static func recognizeShortcutKey(
        _ state: inout GestureState,
        _ event: RawKeyEvent,
    ) -> [Gesture] {
        event.trigger == state.pasteLast.trigger ? recognizePasteLast(&state, event) : []
    }

    private static func isLive(
        _ phase: GestureState.Phase,
        at instant: ContinuousClock.Instant,
    )
        -> Bool
    {
        switch phase {
        case .idle, .endingPress: false
        case .pressing, .handsFreePressing, .handsFree: true
        case .tapped(let releasedAt): instant - releasedAt <= GestureTiming.doubleTapWindow
        }
    }

    private static func recognizeEscape(
        _ state: inout GestureState,
        _ event: RawKeyEvent,
        at instant: ContinuousClock.Instant,
    ) -> [Gesture] {
        guard event.phase == .pressed, state.dictateKey.isPlainEscape(event) else { return [] }
        guard isLive(state.phase, at: instant) else { return [] }
        state.phase = .idle
        return [.cancel]
    }

    private static func recognizePasteLast(
        _ state: inout GestureState,
        _ event: RawKeyEvent,
    ) -> [Gesture] {
        switch event.phase {
        case .released:
            state.isPasteLastDown = false
            return []
        case .pressed:
            guard !state.isPasteLastDown, state.pasteLast.matchesPress(event) else { return [] }
            state.isPasteLastDown = true
            return [.pasteLast]
        }
    }

    private static func recognizePress(
        _ state: inout GestureState,
        _ event: RawKeyEvent,
        at instant: ContinuousClock.Instant,
    ) -> [Gesture] {
        switch state.phase {
        case .pressing, .handsFreePressing, .endingPress:
            return []
        case .handsFree:
            state.phase = .endingPress
            return [.handsFreeEnded]
        case .tapped(let releasedAt) where instant - releasedAt <= GestureTiming.doubleTapWindow:
            state.phase = .handsFreePressing
            return [.handsFreeBegan]
        case .tapped, .idle:
            return beginPress(&state, event, at: instant)
        }
    }

    private static func beginPress(
        _ state: inout GestureState,
        _ event: RawKeyEvent,
        at instant: ContinuousClock.Instant,
    ) -> [Gesture] {
        guard let match = state.dictateKey.dictateMatch(for: event) else {
            state.phase = .idle
            return []
        }
        switch match {
        case .dictate:
            state.phase = .pressing(since: instant, isEdit: false)
            return [.pressBegan]
        case .edit:
            state.phase = .pressing(since: instant, isEdit: true)
            return [.editBegan]
        }
    }

    private static func recognizeRelease(
        _ state: inout GestureState,
        at instant: ContinuousClock.Instant,
    ) -> [Gesture] {
        switch state.phase {
        case .idle, .tapped, .handsFree:
            return []
        case .handsFreePressing:
            state.phase = .handsFree
            return []
        case .endingPress:
            state.phase = .idle
            return []
        case .pressing(let since, let isEdit):
            let isTap = !isEdit && instant - since < GestureTiming.tapLimit
            state.phase = isTap ? .tapped(releasedAt: instant) : .idle
            return [.released]
        }
    }
}
