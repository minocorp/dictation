public import Core

public struct SessionEnvironment: Sendable {
    let history: any HistoryStore
    let preferences: @Sendable () -> Preferences
    let clock: any Clock<Duration>

    public init(
        history: any HistoryStore,
        preferences: @escaping @Sendable () -> Preferences,
        clock: any Clock<Duration>,
    ) {
        self.history = history
        self.preferences = preferences
        self.clock = clock
    }
}
