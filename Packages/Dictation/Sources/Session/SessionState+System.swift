import Core

extension SessionState {
    mutating func handle(_ timer: SessionTimer) -> [Effect] {
        switch timer {
        case .tapThreshold:
            if active?.phase == .capturing { active?.hasPassedTapThreshold = true }
            return []
        case .doubleTapWindow:
            return active?.phase == .tapped ? finishLive() : []
        case .handsFreeSecond:
            return tickSecond()
        case .processingDelay:
            if indicator == .armed { indicator = .visible }
            return []
        case .hudExpiry:
            notice = nil
            return []
        }
    }

    mutating func handle(_ system: SystemEvent) -> [Effect] {
        switch system {
        case .permission(let status):
            permissions = status
            return clearResolvedProblem() + endLiveOnPermissionLoss()
        case .preferences(let updated):
            preferences = updated
            return []
        case .hotkeyFailed(let error):
            return post(HUDMapping.hud(for: .hotkey(error)))
        case .systemSleep, .screenLocked:
            return holdForLockedSession()
        }
    }

    mutating func handle(_ request: Request) -> [Effect] {
        switch request {
        case .modelReady(let stage, let pending):
            switch stage {
            case .speech:
                for item in pending.sorted(by: { $0.date < $1.date }) { enqueueBackground(item) }
            case .cleanup:
                break
            }
        case .retry(let item):
            enqueueBackground(item)
        case .launched(let orphans, let date):
            for url in orphans { enqueueOrphan(url, at: date) }
        }
        return []
    }

    private mutating func tickSecond() -> [Effect] {
        guard var live = active, live.mode == .handsFree else { return [] }
        live.elapsed += SessionTiming.handsFreeSecond
        live.silent += SessionTiming.handsFreeSecond
        active = live
        if let limit = preferences.handsFreeSilenceLimit.duration, live.silent >= limit {
            return finishLive()
        }
        return [.startTimer(.handsFreeSecond, SessionTiming.handsFreeSecond)]
    }

    private mutating func holdForLockedSession() -> [Effect] {
        if active != nil { active?.pending.delivery = .keepAsLast }
        let effects = finishLive()
        queue.removeAll { $0.source == .pasteLast && $0.stage != .delivering }
        for index in queue.indices where queue[index].isHoldable {
            queue[index].delivery = .keepAsLast
        }
        return effects
    }

    private mutating func endLiveOnPermissionLoss() -> [Effect] {
        guard active != nil else { return [] }
        if !permissions.isAccessibilityTrusted {
            active?.pending.delivery = .keepAsLast
            return finishLive() + post(HUDMapping.hud(for: .hotkey(.accessibilityNotTrusted)))
        }
        guard permissions.microphone == .denied else { return [] }
        active?.pending.failure = .capture(.permissionDenied)
        return finishLive()
    }

    private mutating func clearResolvedProblem() -> [Effect] {
        guard case .problem(let problem) = notice, isResolved(problem) else { return [] }
        notice = nil
        return [.cancelTimer(.hudExpiry)]
    }

    private func isResolved(_ problem: Problem) -> Bool {
        switch problem {
        case .microphoneDenied: permissions.microphone != .denied
        case .accessibilityOff: permissions.isAccessibilityTrusted
        case .microphoneUnavailable, .passwordField, .couldNotEdit, .selectionTooLong,
            .couldNotTranscribe, .couldNotSave:
            false
        }
    }
}
