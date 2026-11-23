import Core

extension SessionState {
    var derivedHUD: HUDState {
        if let active { return liveHUD(of: active) }
        if let notice { return notice }
        return indicator == .visible ? .processing : .hidden
    }

    mutating func refreshHUD() {
        hud = derivedHUD
    }

    mutating func post(_ notice: HUDState) -> [Effect] {
        guard notice != .hidden else { return [] }
        self.notice = notice
        guard let expiry = SessionTiming.expiry(of: notice) else { return [] }
        return [.startTimer(.hudExpiry, expiry)]
    }

    mutating func dismissNotice() -> [Effect] {
        guard notice != nil else { return [] }
        notice = nil
        return [.cancelTimer(.hudExpiry)]
    }

    mutating func updateIndicator() -> [Effect] {
        let isWorking = queue.contains { $0.isForeground }
        switch (isWorking, indicator) {
        case (true, .off):
            indicator = .armed
            return [.startTimer(.processingDelay, SessionTiming.processingDelay)]
        case (false, .armed):
            indicator = .off
            return [.cancelTimer(.processingDelay)]
        case (false, .visible):
            indicator = .off
            return []
        case (true, .armed), (true, .visible), (false, .off):
            return []
        }
    }

    @discardableResult
    mutating func modify(_ id: DictationID, _ change: (inout Pending) -> Void) -> Bool {
        if var live = active, live.pending.id == id {
            change(&live.pending)
            active = live
            return true
        }
        guard let index = queue.firstIndex(where: { $0.id == id }) else { return false }
        change(&queue[index])
        return true
    }

    private func liveHUD(of live: Active) -> HUDState {
        switch (live.phase, live.mode) {
        case (.selecting, _): .editing
        case (.capturing, .hold), (.tapped, _): .listening
        case (.capturing, .handsFree):
            .handsFree(elapsed: live.elapsed, countdown: countdown(live))
        case (.capturing, .edit): .editing
        }
    }

    private func countdown(_ live: Active) -> Duration? {
        guard let limit = preferences.handsFreeSilenceLimit.duration else { return nil }
        let remaining = limit - live.silent
        return remaining <= SessionTiming.countdownWindow ? remaining : nil
    }
}
