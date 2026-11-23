import Core

extension SessionState {
    mutating func conclude(_ head: Pending, _ verdict: Verdict) -> [Effect]? {
        switch verdict {
        case .noSpeech:
            return concludeWithoutSpeech(head)
        case .failed(let failure):
            return concludeFailed(head, failure)
        case .text(let text):
            switch head.delivery {
            case .insert: return beginDelivery(head, text: text)
            case .keepAsLast: return keep(head, text: text, remembers: true)
            case .background: return keep(head, text: text, remembers: false)
            case .canceled: return drop(head)
            }
        }
    }

    mutating func finishDelivery(id: DictationID, outcome: InsertOutcome) -> [Effect] {
        guard let job = queue.first(where: { $0.id == id && $0.stage == .delivering }) else {
            return []
        }
        return finishDelivery(job, outcome: outcome)
    }

    private mutating func beginDelivery(_ head: Pending, text: String) -> [Effect]? {
        guard head.isTargetKnown else { return nil }
        guard let focus = head.target else {
            return finishDelivery(head, outcome: .copied(.noTextField))
        }
        queue[0].stage = .delivering
        return [.insert(head.id, text: text, focus: focus)]
    }

    private mutating func finishDelivery(_ job: Pending, outcome: InsertOutcome) -> [Effect] {
        queue.removeAll { $0.id == job.id }
        let text = job.finalText
        var effects: [Effect] = []
        if case .copied = outcome { effects.append(.copy(text)) }
        if job.source != .pasteLast {
            let keepsAudio = Self.keepsAudio(after: outcome)
            let item = job.historyItem(
                finalText: text,
                status: Self.status(of: outcome),
                keepsAudio: keepsAudio,
            )
            lastResult = LastResult(item: item, target: job.target)
            effects.append(persist(item, of: job))
            if !keepsAudio, let url = job.audioURL { effects.append(.discardAudio(url)) }
            effects += learningEffect(job, text: text, outcome: outcome)
        }
        return effects + post(HUDMapping.hud(for: .insert(outcome)))
    }

    private mutating func keep(_ head: Pending, text: String, remembers: Bool) -> [Effect] {
        queue.removeAll { $0.id == head.id }
        let item = head.historyItem(finalText: text, status: head.keptStatus)
        if remembers { lastResult = LastResult(item: item, target: nil) }
        return [persist(item, of: head)]
    }

    private mutating func concludeWithoutSpeech(_ head: Pending) -> [Effect] {
        queue.removeAll { $0.id == head.id }
        var effects: [Effect] = []
        if head.existing == nil, let url = head.audioURL { effects.append(.discardAudio(url)) }
        if head.delivery == .background, let existing = head.existing, existing.finalText.isEmpty {
            effects.append(.update(head.historyItem(finalText: "", status: .failed)))
        }
        guard head.isForeground, !head.wasTap else { return effects }
        return effects + post(.noSpeech)
    }

    private mutating func concludeFailed(_ head: Pending, _ failure: Failure) -> [Effect] {
        queue.removeAll { $0.id == head.id }
        let isMissingModel = failure == .speech(.modelUnavailable)
        let item = head.historyItem(finalText: "", status: isMissingModel ? .pending : .failed)
        var effects = [persist(item, of: head)]
        guard head.isForeground else { return effects }
        if !head.isEdit { lastResult = LastResult(item: item, target: head.target) }
        effects += post(HUDMapping.hud(for: failure))
        return effects
    }

    private func persist(_ item: HistoryItem, of job: Pending) -> Effect {
        job.existing == nil ? .save(item) : .update(item)
    }

    private func learningEffect(_ job: Pending, text: String, outcome: InsertOutcome) -> [Effect] {
        guard case .inserted = outcome, preferences.learning, job.source == .live,
            job.kind == .dictation, let focus = job.target, !focus.isSecure
        else { return [] }
        return [.observeForLearning(text: text, focus: focus)]
    }

    private static func status(of outcome: InsertOutcome) -> HistoryItem.Status {
        switch outcome {
        case .inserted: .inserted
        case .copied: .copied
        case .refused: .refused
        }
    }

    private static func keepsAudio(after outcome: InsertOutcome) -> Bool {
        switch outcome {
        case .inserted, .copied: true
        case .refused: false
        }
    }
}
