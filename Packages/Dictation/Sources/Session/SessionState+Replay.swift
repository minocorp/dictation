import Core
import Foundation

extension SessionState {
    mutating func restore(stamp: Stamp) -> [Effect] {
        guard let last = lastResult, last.item.finalText.isEmpty, let url = last.item.audioURL,
            !isQueued(itemID: last.item.id)
        else { return [] }
        guard last.item.kind == .dictation else { return post(.problem(.couldNotEdit)) }
        var pending = Pending(
            id: stamp.id,
            date: stamp.date,
            source: .audio(url),
            delivery: .insert,
        )
        pending.existing = last.item
        pending.target = last.target
        pending.isTargetKnown = true
        queue.append(pending)
        return dismissNotice()
    }

    mutating func pasteLast(stamp: Stamp) -> [Effect] {
        queue.append(
            Pending(id: stamp.id, date: stamp.date, source: .pasteLast, delivery: .insert)
        )
        return [.readFocus(stamp.id)]
    }

    mutating func enqueueBackground(_ item: HistoryItem) {
        guard let url = item.audioURL, !isQueued(itemID: item.id) else { return }
        var pending = Pending(
            id: item.id,
            date: item.date,
            source: .audio(url),
            delivery: .background,
        )
        pending.existing = item
        queue.append(pending)
    }

    mutating func enqueueOrphan(_ url: URL, at date: Date) {
        guard let id = DictationID(stem: url.deletingPathExtension().lastPathComponent),
            !isQueued(itemID: id)
        else { return }
        queue.append(Pending(id: id, date: date, source: .audio(url), delivery: .background))
    }

    private func isQueued(itemID: DictationID) -> Bool {
        queue.contains { $0.id == itemID || $0.existing?.id == itemID }
    }
}
