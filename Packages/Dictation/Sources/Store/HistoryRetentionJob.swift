public import Core
public import Foundation

public actor HistoryRetentionJob {
    private static let secondsPerDay: TimeInterval = 86_400
    private static let interval = Duration.seconds(86_400)

    private let store: GRDBHistoryStore
    private let retention: @Sendable () -> HistoryRetention
    private let clock: any Clock<Duration>
    private let now: @Sendable () -> Date
    private var schedule: Task<Void, Never>?

    public init(
        store: GRDBHistoryStore,
        retention: @escaping @Sendable () -> HistoryRetention,
        clock: any Clock<Duration>,
        now: @escaping @Sendable () -> Date,
    ) {
        self.store = store
        self.retention = retention
        self.clock = clock
        self.now = now
    }

    public func runOnce() async throws(StoreError) {
        let current = now()
        // Retention off removes finished items on save; the rest keep the audio window for Restore.
        let days = max(retention().days, 1)
        try await store.purge(
            olderThan: current.addingTimeInterval(-Double(days) * Self.secondsPerDay)
        )
        try await store.expireAudio(olderThan: current.addingTimeInterval(-Self.secondsPerDay))
    }

    public func start() {
        guard schedule == nil else { return }
        let clock = clock
        schedule = Task { [weak self] in
            while !Task.isCancelled {
                await self?.runLoggingFailure()
                guard await clock.sleepUnlessCancelled(for: Self.interval) else { return }
            }
        }
    }

    public func retentionChanged() async {
        await runLoggingFailure()
    }

    public func stop() {
        schedule?.cancel()
        schedule = nil
    }

    private func runLoggingFailure() async {
        do {
            try await runOnce()
        } catch {
            StoreLog.failure("retention", error)
        }
    }
}
