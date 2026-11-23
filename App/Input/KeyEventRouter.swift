import Core
import Hotkeys
import Observation
import Session

@MainActor
internal final class KeyEventRouter {
    private let keys: EventTapKeySource
    private let runner: SessionRunner
    private let preferences: PreferencesStore
    private let sink: KeyCaptureSink
    private var state: GestureState
    private var routing: Task<Void, Never>?
    private var watchingHealth: Task<Void, Never>?
    private var watchingLiveState: Task<Void, Never>?

    init(keys: EventTapKeySource, runner: SessionRunner, preferences: PreferencesStore) {
        self.keys = keys
        self.runner = runner
        self.preferences = preferences
        sink = KeyCaptureSink { [keys] isCapturing in keys.setCapturing(isCapturing) }
        let current = preferences.read()
        state = GestureState(dictateKey: current.dictateKey, pasteLast: current.pasteLastShortcut)
    }

    isolated deinit {
        routing?.cancel()
        watchingHealth?.cancel()
        watchingLiveState?.cancel()
    }

    func start() {
        startTap()
        guard routing == nil else { return }
        let events = keys.events
        routing = Task { [weak self] in
            for await event in events {
                self?.route(event)
            }
        }
        let runner = runner
        watchingLiveState = Task { [weak self] in
            for await isLive in Observations({ runner.state.isLive }) where !isLive {
                self?.resetGesturesIfRunnerEnded()
            }
        }
        let health = keys.health
        watchingHealth = Task { [weak self] in
            for await report in health where !report.isTapEnabled && report.isAccessibilityTrusted {
                self?.runner.hotkeyFailed(.eventTapUnavailable)
            }
        }
    }

    func startTap() {
        do {
            try keys.start()
        } catch {
            runner.hotkeyFailed(error)
        }
    }

    func captureKeys() -> AsyncStream<RawKeyEvent> {
        sink.makeStream()
    }

    func preferencesChanged() {
        let current = preferences.read()
        state = GestureState(dictateKey: current.dictateKey, pasteLast: current.pasteLastShortcut)
    }

    private func resetGesturesIfRunnerEnded() {
        guard !runner.state.isLive, !state.isIdle else { return }
        state.reset()
    }

    private func route(_ event: RawKeyEvent) {
        guard !sink.forward(event) else { return }
        for gesture in GestureRecognizer.recognize(&state, event, at: .now) {
            runner.perform(gesture)
        }
    }
}
