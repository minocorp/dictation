import Foundation
import Synchronization
import os

public enum TimingLog {
    private struct Clockwork {
        let name: String
        let keyDown: ContinuousClock.Instant
        var keyUp: ContinuousClock.Instant?
    }

    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "",
        category: "timing",
    )
    private static let clock = ContinuousClock()
    private static let clockworks = Mutex<[DictationID: Clockwork]>([:])

    public static var executionContext: String {
        "task-priority=\(Task.currentPriority.rawValue) qos=\(qos_class_self().rawValue)"
    }

    public static var isDictationInFlight: Bool { !clockworks.withLock { $0.isEmpty } }

    public static func keyDown(_ id: DictationID) {
        clockworks.withLock {
            $0[id] = Clockwork(name: String(id.stem.prefix(8)), keyDown: clock.now, keyUp: nil)
        }
        mark("key-down", for: id)
    }

    public static func keyUp(_ id: DictationID) {
        clockworks.withLock { $0[id]?.keyUp = clock.now }
        mark("key-up", for: id)
    }

    public static func retire(keeping live: Set<DictationID>) {
        let finished = clockworks.withLock { $0.keys.filter { !live.contains($0) } }
        for id in finished {
            mark("done", for: id)
            clockworks.withLock { $0[id] = nil }
        }
    }

    public static func mark(_ stage: String, _ detail: String = "", for id: DictationID? = nil) {
        let now = clock.now
        let clockwork = id.flatMap { id in clockworks.withLock { $0[id] } }
        let name = clockwork?.name ?? "-"
        let sinceDown = milliseconds(from: clockwork?.keyDown, to: now)
        let sinceUp = milliseconds(from: clockwork?.keyUp, to: now)
        logger.debug(
            "dictation=\(name, privacy: .public) stage=\(stage, privacy: .public) since-key-down-ms=\(sinceDown, privacy: .public) since-key-up-ms=\(sinceUp, privacy: .public) \(detail, privacy: .public)"
        )
    }

    private static func milliseconds(
        from start: ContinuousClock.Instant?,
        to end: ContinuousClock.Instant,
    ) -> Int {
        guard let start else { return -1 }
        return start.duration(to: end).milliseconds
    }
}
