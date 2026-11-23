import Core
import Diagnostics

internal struct RecordingTextInserter: TextInserter {
    let base: any TextInserter
    let log: InsertionResultLog

    func insert(
        _ text: String,
        into target: TargetApp,
        focus: FocusSnapshot,
    ) async -> InsertOutcome {
        let outcome = await base.insert(text, into: target, focus: focus)
        log.record(bundleID: target.bundleID, outcome: outcome)
        return outcome
    }
}
