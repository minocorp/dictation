public import Core
import Foundation
import Synchronization

public final class SystemPermissionMonitor: PermissionMonitor {
    private struct Broadcast {
        var subscribers: [UUID: AsyncStream<PermissionStatus>.Continuation] = [:]
        var poller: Task<Void, Never>?
        var latest: PermissionStatus?
    }

    private let system: any PermissionSystem
    private let clock: any Clock<Duration>
    private let onboardingInterval: Duration
    private let idleInterval: Duration
    private let isOnboardingVisible = Mutex(false)
    private let broadcast = Mutex(Broadcast())

    public var status: AsyncStream<PermissionStatus> {
        AsyncStream(bufferingPolicy: .bufferingNewest(1)) { continuation in
            let id = UUID()
            subscribe(continuation, id: id)
            continuation.onTermination = { [weak self] _ in self?.unsubscribe(id) }
        }
    }

    var currentInterval: Duration {
        isOnboardingVisible.withLock { $0 } ? onboardingInterval : idleInterval
    }

    public convenience init(
        clock: any Clock<Duration> = ContinuousClock(),
        onboardingInterval: Duration = .seconds(1),
        idleInterval: Duration = .seconds(2),
    ) {
        self.init(
            system: LivePermissionSystem(),
            clock: clock,
            onboardingInterval: onboardingInterval,
            idleInterval: idleInterval,
        )
    }

    init(
        system: any PermissionSystem,
        clock: any Clock<Duration>,
        onboardingInterval: Duration,
        idleInterval: Duration,
    ) {
        self.system = system
        self.clock = clock
        self.onboardingInterval = onboardingInterval
        self.idleInterval = idleInterval
    }

    public func setOnboardingVisible(_ isVisible: Bool) {
        isOnboardingVisible.withLock { $0 = isVisible }
    }

    public func request(_ permission: Permission) async {
        switch permission {
        case .microphone: await system.requestMicrophoneAccess()
        case .accessibility: system.promptForAccessibility()
        }
    }

    public func openSettings(for permission: Permission) async {
        for url in permission.settingsURLs where await system.open(url) {
            return
        }
    }

    private func subscribe(_ continuation: AsyncStream<PermissionStatus>.Continuation, id: UUID) {
        broadcast.withLock { broadcast in
            broadcast.subscribers[id] = continuation
            if let latest = broadcast.latest { continuation.yield(latest) }
            guard broadcast.poller == nil else { return }
            broadcast.poller = Task { [weak self] in await self?.poll() }
        }
    }

    private func unsubscribe(_ id: UUID) {
        broadcast.withLock { broadcast in
            broadcast.subscribers[id] = nil
            guard broadcast.subscribers.isEmpty else { return }
            broadcast.poller?.cancel()
            broadcast.poller = nil
            broadcast.latest = nil
        }
    }

    private func publish(_ current: PermissionStatus) {
        let subscribers = broadcast.withLock { broadcast in
            guard broadcast.latest != current else {
                return [] as [AsyncStream<PermissionStatus>.Continuation]
            }
            broadcast.latest = current
            return Array(broadcast.subscribers.values)
        }
        for subscriber in subscribers {
            subscriber.yield(current)
        }
    }

    private func poll() async {
        while !Task.isCancelled {
            publish(
                PermissionStatus(
                    microphone: system.microphoneAccess(),
                    isAccessibilityTrusted: system.isAccessibilityTrusted(),
                )
            )
            do {
                try await clock.sleep(for: currentInterval)
            } catch {
                return
            }
        }
    }
}
