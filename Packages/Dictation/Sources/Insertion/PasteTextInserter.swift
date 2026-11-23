public import Core
public import Pasteboard

public actor PasteTextInserter: TextInserter {
    private let gate = SerialGate()
    private let clipboard: any ClipboardWriter
    private let frontmost: any FrontmostApplication
    private let waits: InsertionWaits
    private let chain: InsertionChain
    private let now: @Sendable () -> ContinuousClock.Instant
    private var previous: PreviousInsert?

    public init(
        transaction: ClipboardTransaction,
        focusReader: any FocusReader,
        clipboard: any ClipboardWriter,
    ) {
        self.init(
            frontmost: SystemFrontmostApplication(),
            modifiers: SystemModifierState(),
            clipboard: clipboard,
            chain: InsertionChain(
                transaction: transaction,
                shortcuts: SystemShortcutPoster(),
                focusReader: focusReader,
                menu: SystemMenuPaster(),
                typer: SystemUnicodeTyper(),
                inputMethod: SystemInputMethodProbe(),
                clock: ContinuousClock(),
            ),
        )
    }

    internal init(
        frontmost: any FrontmostApplication,
        modifiers: any ModifierState,
        clipboard: any ClipboardWriter,
        chain: InsertionChain,
        now: @escaping @Sendable () -> ContinuousClock.Instant = { ContinuousClock.now },
    ) {
        self.frontmost = frontmost
        self.clipboard = clipboard
        self.chain = chain
        waits = InsertionWaits(
            modifiers: modifiers,
            focusReader: chain.focusReader,
            clock: chain.clock,
        )
        self.now = now
    }

    public func insert(
        _ text: String,
        into target: TargetApp,
        focus: FocusSnapshot,
    ) async -> InsertOutcome {
        await gate.run { await self.run(text, into: target, focus: focus) }
    }

    private func run(
        _ text: String,
        into target: TargetApp,
        focus: FocusSnapshot,
    ) async
        -> InsertOutcome
    {
        if focus.isSecure { return .refused(.secureField) }
        if focus.fieldKind == .noField { return await copied(text, because: .noTextField) }
        guard frontmost.frontmostPID() == target.pid else {
            return await copied(text, because: .targetLostFocus)
        }
        guard await waits.modifiersReleased() else {
            return await copied(text, because: .modifiersHeld)
        }
        switch await waits.settledFocus(pid: target.pid) {
        case .ready(let live):
            return await insertReady(text, target: target, focus: focus, live: live)
        case .secure: return .refused(.secureField)
        case .targetChanged: return await copied(text, because: .targetLostFocus)
        case .composingTimeout: return await copied(text, because: .composingTimeout)
        }
    }

    private func insertReady(
        _ text: String,
        target: TargetApp,
        focus: FocusSnapshot,
        live: FocusSnapshot?,
    ) async -> InsertOutcome {
        let fieldID = live?.fieldID ?? focus.fieldID
        let textBefore = live?.textBefore
        let joined = SmartJoiner.join(
            text,
            after: textBefore ?? previousText(pid: target.pid, fieldID: fieldID)
                ?? focus.textBefore,
        )
        guard frontmost.frontmostPID() == target.pid else {
            return await copied(text, because: .targetLostFocus)
        }
        let method = await chain.deliver(
            joined,
            target: InsertionChain.Target(
                pid: target.pid,
                kind: live?.fieldKind ?? focus.fieldKind,
            ),
            textBefore: textBefore,
        )
        guard let method else { return await copied(text, because: .allMethodsFailed) }
        previous = PreviousInsert(
            pid: target.pid,
            fieldID: fieldID,
            text: joined,
            insertedAt: now(),
        )
        return .inserted(method)
    }

    private func previousText(pid: Int32, fieldID: Int?) -> String? {
        guard let previous, previous.continues(pid: pid, fieldID: fieldID, at: now()) else {
            return nil
        }
        return previous.text
    }

    private func copied(_ text: String, because reason: CopyReason) async -> InsertOutcome {
        await clipboard.copyTransient(text)
        return .copied(reason)
    }
}
