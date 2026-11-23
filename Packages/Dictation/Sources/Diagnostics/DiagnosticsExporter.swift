public import Core
import Foundation

public struct DiagnosticsExporter: Sendable {
    public static let systemFileName = "system.json"
    public static let modelsFileName = "models.json"
    public static let insertionsFileName = "insertion-results.json"
    public static let logFileName = "logs/diagnostics.log"

    private struct System: Encodable {
        let appVersion: String
        let machine: MachineInfo
    }

    private struct ModelRecord: Encodable {
        struct FileRecord: Encodable {
            let path: String
            let sha256: String?
        }

        let id: String
        let revision: String?
        let files: [FileRecord]
    }

    private let log: DiagnosticsLog
    private let insertions: InsertionResultLog
    private let machine: MachineInfo
    private let appVersion: String

    public init(
        log: DiagnosticsLog,
        insertions: InsertionResultLog,
        machine: MachineInfo,
        appVersion: String,
    ) {
        self.log = log
        self.insertions = insertions
        self.machine = machine
        self.appVersion = appVersion
    }

    public func makeBundle(
        installedModels: [ModelEntry]
    ) throws(DiagnosticsError) -> DiagnosticsBundle {
        let records = installedModels.filter(\.isDownloadable)
            .map { entry in
                ModelRecord(
                    id: entry.id,
                    revision: entry.revision,
                    files: entry.files.map { .init(path: $0.path, sha256: $0.sha256) },
                )
            }
        return DiagnosticsBundle(
            files: [
                .init(
                    name: Self.systemFileName,
                    data: try encode(System(appVersion: appVersion, machine: machine)),
                ),
                .init(name: Self.modelsFileName, data: try encode(records)),
                .init(name: Self.insertionsFileName, data: try encode(insertions.snapshot())),
                .init(name: Self.logFileName, data: log.recentLog()),
            ]
        )
    }

    private func encode<Value: Encodable>(_ value: Value) throws(DiagnosticsError) -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        do {
            return try encoder.encode(value)
        } catch {
            throw .exportFailed(code: (error as NSError).code)
        }
    }
}
