import Core

extension SessionState {
    mutating func handle(_ input: InputEvent, id: DictationID) -> [Effect] {
        switch input {
        case .started:
            guard active?.pending.id == id else { return [] }
            active?.isCaptureOpen = true
            return [.play(.start)]
        case .focus(let snapshot):
            modify(id) {
                $0.target = snapshot
                $0.isTargetKnown = true
            }
            return []
        case .selection(let selection):
            return receive(selection, id: id)
        case .segment(let segment):
            return receive(segment)
        case .segmentsEnded:
            return endCapture(id: id) { $0.segmentsEnded = true }
        case .finished(let url):
            return endCapture(id: id) {
                $0.audioURL = url ?? $0.audioURL
                $0.isAudioClosed = true
            }
        }
    }

    private mutating func receive(_ selection: Selection, id: DictationID) -> [Effect] {
        guard var live = active, live.pending.id == id, live.phase == .selecting else { return [] }
        switch selection {
        case .text(let text):
            live.pending.kind = .edit(selection: text)
        case .none:
            live.pending.kind = .dictation
            live.mode = .hold
        case .tooLong, .unreadable:
            return discardLive() + post(HUDMapping.hud(for: .selection(selection)))
        }
        live.phase = .capturing
        active = live
        return live.hasReleased ? finishLive() : []
    }

    private mutating func receive(_ segment: Segment) -> [Effect] {
        modify(segment.dictation) { $0.record(segment) }
        if active?.pending.id == segment.dictation { active?.silent = .zero }
        return []
    }

    private mutating func endCapture(
        id: DictationID,
        update: (inout Pending) -> Void,
    ) -> [Effect] {
        let effects = active?.pending.id == id ? finishLive() : []
        modify(id, update)
        return effects
    }
}
