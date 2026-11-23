import Foundation

public actor ClipboardTransaction {
    private struct Ownership {
        let baseline: [PasteboardItem]
        let session: String
        let changeCount: Int
    }

    private struct Baseline {
        let items: [PasteboardItem]
        let wasPending: Bool
    }

    package static let restoreDelay: Duration = .milliseconds(250)
    package static let copyPollInterval: Duration = .milliseconds(10)
    package static let copyPollAttempts = 25

    private let pasteboard: any PasteboardAccess
    private let clock: any Clock<Duration>
    private let gate = SerialGate()
    private var pending: Ownership?
    private var restoreTask: Task<Void, Never>?

    public init() {
        self.init(pasteboard: SystemPasteboard(), clock: ContinuousClock())
    }

    package init(pasteboard: any PasteboardAccess, clock: any Clock<Duration>) {
        self.pasteboard = pasteboard
        self.clock = clock
    }

    package func pasting<T: Sendable>(
        _ text: String,
        perform: @Sendable () async -> T,
    ) async -> T {
        await gate.run {
            let ownership = await self.begin(text: text)
            let result = await perform()
            await self.scheduleRestore(ownership)
            return result
        }
    }

    package func copy(_ text: String) async {
        await gate.run { await self.write(text: text) }
    }

    package func copyingSelection(trigger: @Sendable () async -> Bool) async -> String? {
        await gate.run { await self.readCopiedText(trigger: trigger) }
    }

    #if DEBUG
    package func settle() async {
        await restoreTask?.value
    }
    #endif

    private func begin(text: String) -> Ownership {
        let baseline = adoptBaseline()
        let session = UUID().uuidString
        let changeCount = pasteboard.replace(
            with: [PasteboardItem.transientText(text, session: session)]
        )
        return Ownership(baseline: baseline.items, session: session, changeCount: changeCount)
    }

    private func write(text: String) {
        restoreTask?.cancel()
        restoreTask = nil
        pending = nil
        _ = pasteboard.replace(with: [PasteboardItem.transientText(text, session: nil)])
    }

    private func readCopiedText(trigger: @Sendable () async -> Bool) async -> String? {
        let baseline = adoptBaseline()
        let startCount = pasteboard.changeCount
        let posted = await trigger()
        let changed = posted ? await waitForChange(since: startCount) : false
        let text = changed ? copiedString() : nil
        if changed || baseline.wasPending {
            _ = pasteboard.replace(with: baseline.items)
        }
        return text
    }

    private func adoptBaseline() -> Baseline {
        defer {
            restoreTask?.cancel()
            restoreTask = nil
            pending = nil
        }
        if let pending, isStillOurs(pending) {
            return Baseline(items: pending.baseline, wasPending: true)
        }
        return Baseline(items: pasteboard.items(), wasPending: false)
    }

    private func scheduleRestore(_ ownership: Ownership) {
        pending = ownership
        restoreTask = Task {
            do {
                try await clock.sleep(for: Self.restoreDelay)
            } catch {
                return
            }
            restoreIfOurs(ownership)
        }
    }

    private func restoreIfOurs(_ ownership: Ownership) {
        guard pending?.session == ownership.session else { return }
        pending = nil
        restoreTask = nil
        if isStillOurs(ownership) {
            _ = pasteboard.replace(with: ownership.baseline)
        }
    }

    private func isStillOurs(_ ownership: Ownership) -> Bool {
        guard pasteboard.changeCount == ownership.changeCount else { return false }
        let marker = pasteboard.data(forType: PasteboardType.session)
        return marker.flatMap { String(data: $0, encoding: .utf8) } == ownership.session
    }

    private func waitForChange(since startCount: Int) async -> Bool {
        for _ in 0..<Self.copyPollAttempts {
            if pasteboard.changeCount != startCount { return true }
            do {
                try await clock.sleep(for: Self.copyPollInterval)
            } catch {
                return false
            }
        }
        return pasteboard.changeCount != startCount
    }

    private func copiedString() -> String? {
        pasteboard.data(forType: PasteboardType.plainText)
            .flatMap {
                String(data: $0, encoding: .utf8)
            }
    }
}
