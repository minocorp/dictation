import Core
import Diagnostics
import Foundation

internal struct DiagnosticsKit: Sendable {
    let log: DiagnosticsLog
    let insertions: InsertionResultLog

    static func make(paths: AppPaths) -> DiagnosticsKit {
        DiagnosticsKit(
            log: DiagnosticsLog(
                directory: paths.logs,
                maxBytes: DiagnosticsLog.defaultMaxBytes,
                now: { Date() },
            ),
            insertions: InsertionResultLog(
                fileURL: paths.logs.appending(path: "insertion-results.json")
            ),
        )
    }

    func makeExporter(version: String) -> DiagnosticsExporter {
        DiagnosticsExporter(
            log: log,
            insertions: insertions,
            machine: MachineInfo.current(),
            appVersion: version,
        )
    }
}
