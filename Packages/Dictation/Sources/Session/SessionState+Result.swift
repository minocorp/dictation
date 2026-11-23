import Core

extension SessionState {
    mutating func handle(_ result: ResultEvent, id: DictationID) -> [Effect] {
        switch result {
        case .transcribed(let index, let outcome):
            modify(id) { $0.receive(transcription: outcome, at: index) }
            return []
        case .cleaned(let index, let outcome):
            modify(id) { $0.receive(cleaning: outcome, at: index) }
            return []
        case .edited(let outcome):
            modify(id) { $0.rewrite = .done(outcome) }
            return []
        case .inserted(let outcome):
            return finishDelivery(id: id, outcome: outcome)
        case .failed(let failure):
            return handle(failure, id: id)
        }
    }

    private mutating func handle(_ failure: Failure, id: DictationID) -> [Effect] {
        switch failure {
        case .capture(let error):
            return captureFailed(error, id: id)
        case .speech:
            modify(id) { $0.failure = $0.failure ?? failure }
            return []
        case .cleanup, .store, .hotkey, .selection, .insert:
            return post(HUDMapping.hud(for: failure))
        }
    }

    private mutating func captureFailed(_ error: CaptureError, id: DictationID) -> [Effect] {
        guard error != .cancelled, let live = active, live.pending.id == id else { return [] }
        guard live.isCaptureOpen else {
            active = nil
            let effects = timerCancellations(for: live) + [.cancelWork(id)]
            return effects + post(HUDMapping.hud(for: .capture(error)))
        }
        guard live.phase != .selecting else {
            return discardLive() + post(HUDMapping.hud(for: .capture(error)))
        }
        active?.pending.failure = .capture(error)
        return finishLive()
    }
}
