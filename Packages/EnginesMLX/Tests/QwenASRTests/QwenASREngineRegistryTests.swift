import Core
import Foundation
import ModelCatalog
@testable import QwenASR
import Testing

internal struct QwenASREngineRegistryTests {
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
        #expect(QwenASREngine.kind == "qwen3-asr")
    }

    @Test
    func registeredFactoryBuildsEngineForSpeechEntry() throws {
        let registry = EngineRegistry()
        QwenASREngine.register(in: registry, gate: InferenceGate())
        let engine = try registry.makeSpeechEngine(
            for: entry(family: QwenASREngine.kind, stage: .speech),
            directory: URL(fileURLWithPath: "/tmp/none"),
        )
        #expect(engine is QwenASREngine)
    }

    @Test
    func otherFamilyIsUnknown() {
        let registry = EngineRegistry()
        QwenASREngine.register(in: registry, gate: InferenceGate())
        #expect(throws: ModelError.unknownModel) {
            try registry.makeSpeechEngine(
                for: entry(family: "other", stage: .speech),
                directory: URL(fileURLWithPath: "/tmp/none"),
            )
        }
    }

    @Test
    func missingDirectoryMakesPrepareFail() async {
        let engine = QwenASREngine(
            directory: URL(fileURLWithPath: "/tmp/no-such-model-directory"),
            gate: InferenceGate(),
        )
        await #expect(throws: SpeechError.modelUnavailable) {
            try await engine.prepare()
        }
    }
}
