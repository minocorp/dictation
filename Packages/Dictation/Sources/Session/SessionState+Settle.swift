import Core

extension SessionState {
    mutating func settle() -> [Effect] {
        var effects = advanceAll()
        effects += settleCanceled()
        effects += settleQueue()
        effects += updateIndicator()
        return effects
    }

    private mutating func advanceAll() -> [Effect] {
        var effects: [Effect] = []
        let languages = preferences.languages
        if var live = active {
            effects += live.pending.advance(languages: languages)
            active = live
        }
        for index in queue.indices {
            effects += queue[index].advance(languages: languages)
        }
        return effects
    }

    private mutating func settleCanceled() -> [Effect] {
        var effects: [Effect] = []
        for job in queue where job.delivery == .canceled && job.isAudioClosed {
            queue.removeAll { $0.id == job.id }
            let item = job.historyItem(finalText: "", status: .canceled)
            lastResult = LastResult(item: item, target: job.target)
            effects.append(.save(item))
        }
        return effects
    }

    private mutating func settleQueue() -> [Effect] {
        var effects: [Effect] = []
        while let head = queue.first, let step = settleHead(head) {
            effects += step
        }
        return effects
    }

    private mutating func settleHead(_ head: Pending) -> [Effect]? {
        switch head.stage {
        case .waiting:
            return start(head)
        case .delivering:
            return nil
        case .running:
            guard let verdict = head.verdict else { return nil }
            return conclude(head, verdict)
        }
    }

    private mutating func start(_ head: Pending) -> [Effect]? {
        switch head.source {
        case .live:
            queue[0].stage = .running
            return []
        case .audio(let url):
            queue[0].stage = .running
            return [.readAudio(head.id, url)]
        case .pasteLast:
            return startPasteLast(head)
        }
    }

    private mutating func startPasteLast(_ head: Pending) -> [Effect]? {
        guard head.isTargetKnown else { return nil }
        guard let last = lastResult else { return drop(head) }
        queue[0].stage = .running
        if !last.item.finalText.isEmpty {
            let text = last.item.finalText
            queue[0].segments = [0: .cleaned(raw: text, text: text)]
            queue[0].segmentsEnded = true
            return []
        }
        guard let url = last.item.audioURL else { return drop(head) }
        guard last.item.kind == .dictation else { return refuseEdit(head) }
        queue[0].source = .audio(url)
        queue[0].existing = last.item
        return [.readAudio(head.id, url)]
    }

    private mutating func refuseEdit(_ head: Pending) -> [Effect] {
        drop(head) + post(.problem(.couldNotEdit))
    }

    mutating func drop(_ head: Pending) -> [Effect] {
        queue.removeAll { $0.id == head.id }
        return []
    }
}
