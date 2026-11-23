import Foundation
import Session
import Sparkle

@MainActor
internal final class IdleUpdateDelegate: NSObject, @MainActor SPUUpdaterDelegate {
    private let runner: SessionRunner
    private var waiting: Task<Void, Never>?

    init(runner: SessionRunner) {
        self.runner = runner
    }

    isolated deinit {
        waiting?.cancel()
    }

    func updater(
        _ updater: SPUUpdater,
        shouldPostponeRelaunchForUpdate item: SUAppcastItem,
        untilInvokingBlock installHandler: @escaping () -> Void,
    ) -> Bool {
        guard !runner.state.isIdle else { return false }
        let runner = runner
        waiting = Task {
            for await isIdle in Observations({ runner.state.isIdle }) where isIdle {
                installHandler()
                return
            }
        }
        return true
    }
}
