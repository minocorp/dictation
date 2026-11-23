import Core
import Pasteboard

internal struct InsertionChain: Sendable {
    struct Target: Sendable {
        let pid: Int32
        let kind: FieldKind
    }

    private enum Attempt: Sendable {
        case done(InsertMethod)
        case failed
        case abandoned
    }

    let transaction: ClipboardTransaction
    let shortcuts: any ShortcutPosting
    let focusReader: any FocusReader
    let menu: any MenuPaster
    let typer: any UnicodeTyper
    let inputMethod: any InputMethodProbe
    let clock: any Clock<Duration>

    func deliver(_ text: String, target: Target, textBefore: String?) async -> InsertMethod? {
        switch await clipboardMethod(text, target: target, textBefore: textBefore) {
        case .done(let method): return method
        case .abandoned: return nil
        case .failed: break
        }
        guard await !inputMethod.isInputMethodActive() else { return nil }
        guard typer.type(text) else { return nil }
        let evidence = await settledEvidence(since: textBefore, target: target)
        return evidence.provesFailure(in: target.kind) ? nil : .typedUnicode
    }

    private func clipboardMethod(
        _ text: String,
        target: Target,
        textBefore: String?,
    ) async -> Attempt {
        await transaction.pasting(text) {
            if await shortcuts.post(.paste) {
                let proof = await settledEvidence(since: textBefore, target: target)
                if proof == .targetGone { return .abandoned }
                if !proof.provesFailure(in: target.kind) { return .done(.pasteShortcut) }
            }
            guard menu.pressPaste(pid: target.pid) else { return .failed }
            let proof = await settledEvidence(since: textBefore, target: target)
            if proof == .targetGone { return .abandoned }
            return proof.provesFailure(in: target.kind) ? .failed : .done(.pasteMenu)
        }
    }

    private func settledEvidence(
        since textBefore: String?,
        target: Target,
    ) async
        -> InsertionEvidence
    {
        let first = await evidence(
            since: textBefore,
            pid: target.pid,
            wait: InsertionTiming.evidenceWait,
        )
        guard first.provesFailure(in: target.kind), first == .unchanged else { return first }
        return await evidence(
            since: textBefore,
            pid: target.pid,
            wait: InsertionTiming.lateEvidenceWait,
        )
    }

    private func evidence(
        since textBefore: String?,
        pid: Int32,
        wait: Duration,
    ) async
        -> InsertionEvidence
    {
        let polls =
            textBefore == nil
            ? 1
            : InsertionTiming.polls(in: wait, every: InsertionTiming.evidencePoll)
        var readable = textBefore != nil
        for _ in 0..<polls {
            guard await clock.sleepUnlessCancelled(for: InsertionTiming.evidencePoll) else {
                return .unreadable
            }
            guard let live = await focusReader.snapshot() else {
                if textBefore == nil { return .unreadable }
                readable = false
                continue
            }
            if live.target.pid != pid || live.isSecure { return .targetGone }
            guard let before = textBefore, let after = live.textBefore else {
                readable = false
                continue
            }
            if after != before { return .confirmed }
        }
        return readable ? .unchanged : .unreadable
    }
}
