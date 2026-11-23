import AppKit
import ModelCatalog
import Session

@MainActor
internal final class SystemEvents {
    private let runner: SessionRunner
    private let residency: ModelResidency
    private var tasks: [Task<Void, Never>] = []
    private var memoryPressure: (any DispatchSourceMemoryPressure)?

    init(runner: SessionRunner, residency: ModelResidency) {
        self.runner = runner
        self.residency = residency
    }

    isolated deinit {
        for task in tasks {
            task.cancel()
        }
        memoryPressure?.cancel()
    }

    func start() {
        let workspace = NSWorkspace.shared.notificationCenter
        let distributed = DistributedNotificationCenter.default()
        observe(workspace, NSWorkspace.willSleepNotification) { $0.runner.systemWillSleep() }
        observe(distributed, Notification.Name("com.apple.screenIsLocked")) {
            $0.runner.screenDidLock()
        }
        observe(distributed, Notification.Name("com.apple.screensaver.didstart")) {
            $0.runner.screenDidLock()
        }
        startMemoryPressure()
    }

    private func observe(
        _ center: NotificationCenter,
        _ name: Notification.Name,
        handler: @escaping @MainActor (SystemEvents) -> Void,
    ) {
        tasks.append(
            Task { [weak self] in
                for await _ in center.notifications(named: name) {
                    guard let self else { return }
                    handler(self)
                }
            }
        )
    }

    private func startMemoryPressure() {
        let source = DispatchSource.makeMemoryPressureSource(
            eventMask: [.warning, .critical],
            queue: .main,
        )
        source.setEventHandler { [weak self] in
            Task { @MainActor in await self?.didReceiveMemoryPressure() }
        }
        source.activate()
        memoryPressure = source
    }

    private func didReceiveMemoryPressure() async {
        await residency.memoryPressure()
    }
}
