import Core
import Foundation
@testable import ModelCatalog
import Testing

internal struct ModelManifestTests {
    private struct InvalidCase: Sendable {
        let name: String
        let entry: ModelEntry
        let issue: ManifestIssue
    }

    private static let digest = String(repeating: "b", count: 64)

    private static let invalidCases = [
        InvalidCase(
            name: "gpl license",
            entry: ManifestFixtures.entry(license: "GPL-3.0"),
            issue: .disallowedLicense(id: "test-model"),
        ),
        InvalidCase(
            name: "empty license",
            entry: ManifestFixtures.entry(license: ""),
            issue: .disallowedLicense(id: "test-model"),
        ),
        InvalidCase(
            name: "null revision",
            entry: ManifestFixtures.entry(revision: nil),
            issue: .missingRevision(id: "test-model"),
        ),
        InvalidCase(
            name: "branch name revision",
            entry: ManifestFixtures.entry(revision: "main"),
            issue: .missingRevision(id: "test-model"),
        ),
        InvalidCase(
            name: "null hash",
            entry: ManifestFixtures.entry(files: [ModelFile(path: "m.bin", bytes: 10, sha256: nil)]
            ),
            issue: .missingHash(id: "test-model", path: "m.bin"),
        ),
        InvalidCase(
            name: "short hash",
            entry: ManifestFixtures.entry(files: [
                ModelFile(path: "m.bin", bytes: 10, sha256: "abc")
            ]),
            issue: .invalidHash(id: "test-model", path: "m.bin"),
        ),
        InvalidCase(
            name: "path traversal",
            entry: ManifestFixtures.entry(
                files: [ModelFile(path: "../escape", bytes: 10, sha256: digest)]
            ),
            issue: .unsafePath(id: "test-model", path: "../escape"),
        ),
        InvalidCase(
            name: "absolute path",
            entry: ManifestFixtures.entry(files: [
                ModelFile(path: "/etc/x", bytes: 10, sha256: digest)
            ]),
            issue: .unsafePath(id: "test-model", path: "/etc/x"),
        ),
        InvalidCase(
            name: "empty file list",
            entry: ManifestFixtures.entry(files: [], downloadBytes: 0),
            issue: .emptyFileList(id: "test-model"),
        ),
        InvalidCase(
            name: "byte total mismatch",
            entry: ManifestFixtures.entry(downloadBytes: 11),
            issue: .downloadBytesMismatch(id: "test-model"),
        ),
        InvalidCase(
            name: "uppercase id",
            entry: ManifestFixtures.entry(id: "Test"),
            issue: .invalidID("Test"),
        ),
        InvalidCase(
            name: "built-in format",
            entry: ManifestFixtures.entry(format: .builtIn),
            issue: .builtInFormat(id: "test-model"),
        ),
        InvalidCase(
            name: "default for a tier below its minimum RAM",
            entry: ManifestFixtures.entry(minRAMGB: 24, defaultFor: [.ram16]),
            issue: .defaultBelowMinimumRAM(id: "test-model"),
        ),
        InvalidCase(
            name: "malformed repo",
            entry: ManifestFixtures.entry(repo: "no-owner"),
            issue: .invalidRepo(id: "test-model"),
        ),
    ]

    @Test
    func realManifestDecodesAndIsFullyPinned() throws {
        let manifest = try ModelManifest.load(from: ManifestFixtures.realManifestURL)
        #expect(manifest.models.count == 7)
        #expect(manifest.issues.isEmpty)
        #expect(manifest.models.allSatisfy { $0.revision == $0.observedRevision })
    }

    @Test
    func realManifestHasOneDefaultPerStageAndTier() throws {
        let manifest = try ModelManifest.load(from: ManifestFixtures.realManifestURL)
        for stage in ModelStage.allCases {
            for tier in [RAMTier.ram16, .ram24] {
                let defaults = manifest.entries(stage: stage)
                    .filter { $0.defaultFor.contains(tier) }
                #expect(defaults.count == 1)
            }
        }
    }

    @Test(arguments: invalidCases.map(\.name))
    func invalidEntryIsRejected(name: String) throws {
        let invalid = try #require(Self.invalidCases.first { $0.name == name })
        let manifest = ModelManifest(schemaVersion: 1, models: [invalid.entry])
        #expect(manifest.issues.contains(invalid.issue))
    }

    @Test
    func unsupportedSchemaVersionIsRejected() {
        let manifest = ModelManifest(schemaVersion: 2, models: [])
        #expect(manifest.issues == [.unsupportedSchemaVersion(2)])
    }

    @Test
    func duplicateIDIsRejected() {
        let manifest = ModelManifest(
            schemaVersion: 1,
            models: [ManifestFixtures.entry(), ManifestFixtures.entry()],
        )
        #expect(manifest.issues == [.duplicateID("test-model")])
    }

    @Test
    func decodeThrowsLoadFailedForInvalidManifest() throws {
        let manifest = ModelManifest(
            schemaVersion: 1,
            models: [ManifestFixtures.entry(revision: nil)],
        )
        let data = try JSONEncoder().encode(manifest)
        #expect(throws: ModelError.loadFailed) { try ModelManifest.decode(data) }
    }

    @Test
    func decodeThrowsLoadFailedForGarbage() {
        #expect(throws: ModelError.loadFailed) { try ModelManifest.decode(Data("{".utf8)) }
    }

    @Test
    func loadThrowsFileFailedForMissingFile() {
        let missing = URL(filePath: "/nonexistent/manifest.json")
        #expect(throws: ModelError.self) { try ModelManifest.load(from: missing) }
    }
}
