public import Core
public import Foundation

@MainActor
@Observable
public final class SessionRunner {
    public private(set) var state: SessionState

    let inputs: SessionInputs
    let engines: SessionEngines
    let outputs: SessionOutputs
    let environment: SessionEnvironment

    @ObservationIgnored
    var captures: [DictationID: Task<Void, Never>] = [:]
    @ObservationIgnored
    var tracked: [UUID: TrackedTask] = [:]
    @ObservationIgnored
    var timers: [SessionTimer: ScheduledTimer] = [:]
    @ObservationIgnored
    var nextTimerGeneration = 0
    @ObservationIgnored
    var liveCapture: DictationID?
    @ObservationIgnored
    var tails: [WorkLane: Task<Void, Never>] = [:]
    @ObservationIgnored
    private var inbox: [Event] = []
    @ObservationIgnored
    private var isDraining = false

    public init(
        inputs: SessionInputs,
        engines: SessionEngines,
        outputs: SessionOutputs,
        environment: SessionEnvironment,
    ) {
        self.inputs = inputs
        self.engines = engines
        self.outputs = outputs
        self.environment = environment
        state = SessionState(
            preferences: environment.preferences(),
            permissions: PermissionStatus(
                microphone: .notDetermined,
                isAccessibilityTrusted: true,
            ),
        )
    }

    public func perform(_ gesture: Gesture) {
        let stamp = Stamp(id: DictationID(), date: Date())
        switch gesture {
        case .pressBegan, .editBegan:
            if state.active == nil { TimingLog.keyDown(stamp.id) }
        case .released, .handsFreeBegan, .handsFreeEnded, .stop, .cancel, .abandon, .restore,
            .pasteLast:
            break
        }
        send(.gesture(gesture, stamp))
    }

    public func permissionChanged(_ status: PermissionStatus) {
        send(.system(.permission(status)))
    }

    public func preferencesChanged() {
        send(.system(.preferences(environment.preferences())))
    }

    public func hotkeyFailed(_ error: HotkeyError) {
        send(.system(.hotkeyFailed(error)))
    }

    public func systemWillSleep() {
        send(.system(.systemSleep))
    }

    public func screenDidLock() {
        send(.system(.screenLocked))
    }

    public func launch() async {
        inputs.keys.setPolicy(state.tapPolicy)
        let history = environment.history
        let orphans = await Result.awaiting { () async throws(StoreError) -> [URL] in
            try await history.orphanAudio()
        }
        send(.request(.launched(orphans: orphans.value ?? [], at: Date())))
    }

    public func modelBecameReady(_ stage: ModelStage) async {
        let history = environment.history
        let pending = await Result.awaiting { () async throws(StoreError) -> [HistoryItem] in
            try await history.pending()
        }
        send(.request(.modelReady(stage, pending: pending.value ?? [])))
    }

    public func retry(_ id: DictationID) async {
        let history = environment.history
        let item = await Result.awaiting { () async throws(StoreError) -> HistoryItem in
            try await history.item(id: id)
        }
        guard let found = item.value else { return }
        send(.request(.retry(found)))
    }

    func send(_ event: Event) {
        inbox.append(event)
        guard !isDraining else { return }
        isDraining = true
        while !inbox.isEmpty {
            let next = inbox.removeFirst()
            for effect in reduce(&state, next) {
                run(effect)
            }
        }
        isDraining = false
        TimingLog.retire(keeping: state.dictationIDs)
    }
}
