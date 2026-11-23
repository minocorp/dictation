public import Core
public import CoreGraphics
public import Observation

@MainActor
@Observable
public final class HUDModel {
    private static let firstUpdateElapsed = 1.0 / 30
    private static let maximumUpdateInterval = Duration.milliseconds(33)
    private static let reducedMotionUpdateInterval = Duration.milliseconds(66)

    public var reducesMotion = false
    private(set) var displayed = HUDState.hidden
    private(set) var isPresented = false
    public var contentSize = CGSize.zero

    var barHeights = LevelMeter.restingHeights

    @ObservationIgnored
    private let source: @MainActor () -> HUDState
    @ObservationIgnored
    private let levels: AsyncStream<Float>
    @ObservationIgnored
    private let actions: HUDActions
    @ObservationIgnored
    private let clock = ContinuousClock()
    @ObservationIgnored
    private var meter = LevelMeter()
    @ObservationIgnored
    private var lastUpdate: ContinuousClock.Instant?
    @ObservationIgnored
    private var previous = HUDState.hidden

    public var state: HUDState { source() }

    public var acceptsMouse: Bool {
        switch state {
        case .handsFree, .canceled: true
        case .problem(let problem): problem.fix != nil
        case .hidden, .listening, .editing, .processing, .copied, .saved, .noSpeech: false
        }
    }

    public init(
        state: @escaping @MainActor () -> HUDState,
        levels: AsyncStream<Float>,
        actions: HUDActions,
    ) {
        source = state
        self.levels = levels
        self.actions = actions
    }

    public func watchState() async {
        for await current in Observations({ self.state }) {
            apply(current)
        }
    }

    public func watchLevels() async {
        for await level in levels {
            advanceMeter(toward: level)
        }
    }

    func stop() {
        actions.perform(.stop)
    }

    func cancel() {
        actions.perform(.cancel)
    }

    func restore() {
        actions.perform(.restore)
    }

    func openFix(for problem: Problem) {
        guard let fix = problem.fix else { return }
        actions.openFix(fix)
    }

    func apply(_ current: HUDState) {
        if let announcement = HUDAnnouncement.between(previous, current) {
            actions.announce(announcement.text)
        }
        previous = current
        isPresented = current != .hidden
        if isPresented { displayed = current }
        if !isShowingLevels(current) { resetMeter() }
    }

    func advanceMeter(toward level: Float) {
        guard isShowingLevels(state), isPresented else { return }
        let now = clock.now
        let interval =
            reducesMotion ? Self.reducedMotionUpdateInterval : Self.maximumUpdateInterval
        if let lastUpdate, lastUpdate.duration(to: now) < interval { return }
        let elapsed =
            lastUpdate.map { $0.duration(to: now) / .seconds(1) } ?? Self.firstUpdateElapsed
        lastUpdate = now
        meter.advance(toward: level, elapsed: elapsed, smoothing: !reducesMotion)
        barHeights = meter.barHeights
    }

    private func resetMeter() {
        meter.reset()
        lastUpdate = nil
        barHeights = LevelMeter.restingHeights
    }

    private func isShowingLevels(_ state: HUDState) -> Bool {
        switch state {
        case .listening, .handsFree, .editing: true
        case .hidden, .processing, .copied, .canceled, .saved, .noSpeech, .problem: false
        }
    }
}
