import Core

extension SessionState {
    mutating func handle(_ gesture: Gesture, stamp: Stamp) -> [Effect] {
        switch gesture {
        case .pressBegan: begin(.hold, stamp: stamp)
        case .editBegan: begin(.edit, stamp: stamp)
        case .released: release()
        case .handsFreeBegan: enterHandsFree()
        case .handsFreeEnded: leaveHandsFree()
        case .stop: finishLive()
        case .cancel: cancelLive()
        case .abandon: abandonLive()
        case .restore: restore(stamp: stamp)
        case .pasteLast: pasteLast(stamp: stamp)
        }
    }

    private var blockingFailure: Failure? {
        guard permissions.isAccessibilityTrusted else { return .hotkey(.accessibilityNotTrusted) }
        switch permissions.microphone {
        case .denied: return .capture(.permissionDenied)
        case .notDetermined, .granted: return nil
        }
    }

    private mutating func begin(_ mode: Mode, stamp: Stamp) -> [Effect] {
        guard active == nil else { return [] }
        if let failure = blockingFailure { return post(HUDMapping.hud(for: failure)) }
        let isEdit = mode == .edit
        var pending = Pending(id: stamp.id, date: stamp.date, source: .live, delivery: .insert)
        if isEdit { pending.kind = .editPending }
        var live = Active(pending: pending, mode: mode)
        live.phase = isEdit ? .selecting : .capturing
        live.hasPassedTapThreshold = isEdit
        active = live
        var effects = dismissNotice() + [.readFocus(stamp.id)]
        effects.append(.startCapture(stamp.id, device: preferences.microphone))
        if isEdit { return effects + [.readSelection(stamp.id)] }
        effects.append(.startTimer(.tapThreshold, GestureTiming.tapLimit))
        return effects
    }

    private mutating func release() -> [Effect] {
        guard var live = active else { return [] }
        switch live.mode {
        case .handsFree:
            return []
        case .edit:
            guard live.phase != .selecting else {
                live.hasReleased = true
                active = live
                return []
            }
            return finishLive()
        case .hold:
            guard live.phase == .capturing else { return [] }
            guard !live.hasPassedTapThreshold else { return finishLive() }
            live.phase = .tapped
            active = live
            return [
                .cancelTimer(.tapThreshold),
                .startTimer(.doubleTapWindow, GestureTiming.doubleTapWindow),
            ]
        }
    }

    private mutating func enterHandsFree() -> [Effect] {
        guard var live = active, live.mode == .hold, live.phase != .selecting else { return [] }
        let effects = timerCancellations(for: live)
        live.mode = .handsFree
        live.phase = .capturing
        live.hasPassedTapThreshold = true
        active = live
        return effects + [.startTimer(.handsFreeSecond, SessionTiming.handsFreeSecond)]
    }

    private mutating func leaveHandsFree() -> [Effect] {
        guard active?.mode == .handsFree else { return [] }
        return finishLive()
    }

    mutating func finishLive() -> [Effect] {
        guard var live = active else { return [] }
        guard live.phase != .selecting else { return discardLive() }
        active = nil
        live.pending.wasTap = live.mode == .hold && !live.hasPassedTapThreshold
        queue.append(live.pending)
        return timerCancellations(for: live) + [.stopCapture(live.pending.id), .play(.finish)]
    }

    private mutating func cancelLive() -> [Effect] {
        guard let live = active else { return [] }
        guard live.phase != .selecting else { return discardLive() }
        active = nil
        let id = live.pending.id
        var pending = live.pending
        pending.delivery = .canceled
        queue.append(pending)
        let effects = timerCancellations(for: live) + [.cancelWork(id)]
        return effects + [.stopCapture(id), .play(.cancel)] + post(.canceled)
    }

    private mutating func abandonLive() -> [Effect] {
        discardLive()
    }

    mutating func discardLive() -> [Effect] {
        guard let live = active else { return [] }
        active = nil
        let id = live.pending.id
        return timerCancellations(for: live) + [.cancelWork(id), .discardCapture(id)]
    }

    func timerCancellations(for live: Active) -> [Effect] {
        var effects: [Effect] = []
        if live.phase == .capturing, !live.hasPassedTapThreshold {
            effects.append(.cancelTimer(.tapThreshold))
        }
        if live.phase == .tapped { effects.append(.cancelTimer(.doubleTapWindow)) }
        if live.mode == .handsFree { effects.append(.cancelTimer(.handsFreeSecond)) }
        return effects
    }
}
