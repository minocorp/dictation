import Core
@testable import Diagnostics
import Foundation
import Testing

internal struct DiagnosticsBundleTests {
    private let directory = TestDirectory()

    private func makeBundle(models: [ModelEntry] = []) throws -> DiagnosticsBundle {
        let log = DiagnosticsLog(
            directory: directory.url.appending(path: "logs"),
            maxBytes: 10_000,
            now: { Date(timeIntervalSince1970: 0) },
        )
        log.info("Insertion", "inserted via pasteShortcut in 12 ms")
        let insertions = InsertionResultLog(fileURL: directory.url.appending(path: "results.json"))
        insertions.record(bundleID: "com.apple.Notes", outcome: .inserted(.pasteShortcut))
        let exporter = DiagnosticsExporter(
            log: log,
            insertions: insertions,
            machine: MachineInfo(osVersion: "macOS 26.1", chip: "Apple M4", ramGB: 24),
            appVersion: "1.0",
        )
        return try exporter.makeBundle(installedModels: models)
    }

    private func installedModel() -> ModelEntry {
        ModelEntry(
            id: "qwen3-asr-0.6b-4bit",
            stage: .speech,
            displayName: "Qwen",
            family: "qwen3-asr",
            repo: "mlx-community/x",
            revision: String(repeating: "a", count: 40),
            observedRevision: nil,
            format: .mlxSafetensors,
            quant: "4bit",
            license: "Apache-2.0",
            licenseVerified: true,
            languages: ["ko"],
            minRAMGB: 8,
            downloadBytes: 1,
            files: [
                ModelFile(
                    path: "model.safetensors",
                    bytes: 1,
                    sha256: String(repeating: "c", count: 64),
                )
            ],
            defaultFor: [],
            runtime: nil,
            verified: [],
            unverified: nil,
        )
    }

    @Test
    func listsExactlyTheDiagnosticFiles() throws {
        #expect(
            try makeBundle().fileNames == [
                "system.json", "models.json", "insertion-results.json", "logs/diagnostics.log",
            ]
        )
    }

    @Test
    func containsNoAudioFiles() throws {
        let bundle = try makeBundle(models: [installedModel()])
        #expect(!bundle.fileNames.contains { $0.hasSuffix(".caf") })
        #expect(!bundle.files.contains { $0.data.starts(with: Data("caff".utf8)) })
    }

    @Test
    func systemFileHoldsOSChipAndRAM() throws {
        let bundle = try makeBundle()
        let system = try #require(bundle.files.first { $0.name == "system.json" })
        let json = try #require(
            try JSONSerialization.jsonObject(with: system.data) as? [String: Any]
        )
        let machine = try #require(json["machine"] as? [String: Any])
        #expect(machine["osVersion"] as? String == "macOS 26.1")
        #expect(machine["chip"] as? String == "Apple M4")
        #expect(machine["ramGB"] as? Int == 24)
    }

    @Test
    func modelsFileHoldsIDsRevisionsAndHashesOnly() throws {
        let bundle = try makeBundle(models: [installedModel(), .appleSpeechAnalyzer])
        let models = try #require(bundle.files.first { $0.name == "models.json" })
        let list = try #require(
            try JSONSerialization.jsonObject(with: models.data) as? [[String: Any]]
        )
        #expect(list.count == 1)
        #expect(Set(list[0].keys) == ["id", "revision", "files"])
        let files = try #require(list[0]["files"] as? [[String: Any]])
        #expect(Set(files[0].keys) == ["path", "sha256"])
    }

    @Test
    func insertionResultsHoldOnlyCountsPerApp() throws {
        let bundle = try makeBundle()
        let file = try #require(bundle.files.first { $0.name == "insertion-results.json" })
        let counts = try JSONDecoder().decode([String: [String: Int]].self, from: file.data)
        #expect(counts == ["com.apple.Notes": ["inserted.pasteShortcut": 1]])
    }

    @Test
    func writtenZipPassesUnzipIntegrityAndRoundTripsContent() throws {
        let bundle = try makeBundle(models: [installedModel()])
        let destination = directory.url.appending(path: "diagnostics.zip")
        try bundle.write(to: destination)
        #expect(try run("/usr/bin/unzip", ["-tqq", destination.path()]).status == 0)
        let listing = try run("/usr/bin/unzip", ["-Z1", destination.path()]).output
        #expect(listing.split(separator: "\n").map(String.init) == bundle.fileNames)
        let log = try run("/usr/bin/unzip", ["-p", destination.path(), "logs/diagnostics.log"])
            .output
        #expect(log.contains("inserted via pasteShortcut in 12 ms"))
    }

    @Test
    func writeToUnwritableLocationThrowsExportFailed() throws {
        let bundle = try makeBundle()
        #expect(throws: DiagnosticsError.self) {
            try bundle.write(to: URL(filePath: "/nonexistent-dir/diagnostics.zip"))
        }
    }

    private func run(
        _ tool: String,
        _ arguments: [String],
    ) throws -> (status: Int32, output: String) {
        let process = Process()
        process.executableURL = URL(filePath: tool)
        process.arguments = arguments
        let pipe = Pipe()
        process.standardOutput = pipe
        try process.run()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        return (process.terminationStatus, String(data: data, encoding: .utf8) ?? "")
    }
}
