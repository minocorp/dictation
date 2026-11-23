import Cleanup
import Core
import Foundation
import ModelCatalog
@testable import QwenCleanup
import Testing

internal struct QwenCleanupEngineRegistryTests {
    private func entry(family: String, stage: ModelStage) -> ModelEntry {
        ModelEntry(
            id: "test",
            stage: stage,
            displayName: "Test",
            family: family,
            repo: "org/test",
            revision: nil,
            observedRevision: nil,
            format: .mlxSafetensors,
            quant: "4bit",
            license: "Apache-2.0",
            licenseVerified: true,
            languages: ["multilingual"],
            minRAMGB: 8,
            downloadBytes: 1,
            files: [],
            defaultFor: [],
            runtime: nil,
            verified: [],
            unverified: nil,
        )
    }

    @Test
    func kindMatchesManifestFamily() {
        #expect(QwenCleanupEngine.kind == "qwen3.5")
    }

    @Test
    func registeredFactoryBuildsEngineForCleanupEntry() throws {
        let registry = EngineRegistry()
        QwenCleanupEngine.register(in: registry, gate: InferenceGate())
        let engine = try registry.makeCleanupEngine(
            for: entry(family: QwenCleanupEngine.kind, stage: .cleanup),
            directory: URL(fileURLWithPath: "/tmp/none"),
        )
        #expect(engine is QwenCleanupEngine)
    }

    @Test
    func speechEntryIsUnknownToCleanupRegistry() {
        let registry = EngineRegistry()
        QwenCleanupEngine.register(in: registry, gate: InferenceGate())
        #expect(throws: ModelError.unknownModel) {
            try registry.makeCleanupEngine(
                for: entry(family: QwenCleanupEngine.kind, stage: .speech),
                directory: URL(fileURLWithPath: "/tmp/none"),
            )
        }
    }

    @Test
    func missingDirectoryMakesPrepareFail() async {
        let engine = QwenCleanupEngine(
            directory: URL(fileURLWithPath: "/tmp/no-such-model-directory"),
            gate: InferenceGate(),
        )
        await #expect(throws: CleanupError.modelUnavailable) {
            try await engine.prepare()
        }
    }
}
