import Cleanup
import Core
import Foundation
import ModelCatalog
import Recognition

internal final class EngineResolver: Sendable {
    private let library: ManifestModelLibrary
    private let preferences: PreferencesStore
    private let appleSpeech: SpeechAnalyzerEngine
    private let speechSlot: EngineSlot<any SpeechEngine>
    private let cleanupSlot: EngineSlot<any CleanupEngine>

    init(
        library: ManifestModelLibrary,
        registry: EngineRegistry,
        residency: ModelResidency,
        gate: InferenceGate,
        preferences: PreferencesStore,
    ) {
        self.library = library
        self.preferences = preferences
        let appleSpeech = SpeechAnalyzerEngine(
            gate: gate,
            languages: { preferences.read().languages },
        )
        self.appleSpeech = appleSpeech
        speechSlot = EngineSlot(
            library: library,
            residency: residency,
            behavior: EngineSlot.Behavior(
                name: "speech",
                fallback: appleSpeech,
                make: { try registry.makeSpeechEngine(for: $0, directory: $1) },
                prepare: { try await $0.prepare() },
                didLoad: { await residency.didLoad($0, id: $1) },
            ),
        )
        cleanupSlot = EngineSlot(
            library: library,
            residency: residency,
            behavior: EngineSlot.Behavior(
                name: "cleanup",
                fallback: FoundationModelsCleanupEngine(gate: gate),
                make: { try registry.makeCleanupEngine(for: $0, directory: $1) },
                prepare: { try await $0.prepare() },
                didLoad: { await residency.didLoad($0, id: $1) },
            ),
        )
    }

    func speech() async -> any SpeechEngine {
        await speechSlot.resolve(selectedEntry(for: .speech))
    }

    func cleanup() async -> any CleanupEngine {
        await cleanupSlot.resolve(selectedEntry(for: .cleanup))
    }

    func warmUp() async {
        async let appleReady: Void = prepareAppleSpeech()
        _ = await speech()
        if preferences.read().cleanup { _ = await cleanup() }
        await appleReady
    }

    func selectedEntries() -> [ModelEntry] {
        [selectedEntry(for: .speech), selectedEntry(for: .cleanup)]
    }

    private func prepareAppleSpeech() async {
        do {
            try await appleSpeech.prepare()
        } catch {
            AppLog.failure("prepare Apple speech assets", error)
        }
    }

    private func selectedEntry(for stage: ModelStage) -> ModelEntry {
        let recommended = library.recommended()
        let fallback = stage == .speech ? recommended.speech : recommended.cleanup
        let choice =
            stage == .speech ? preferences.read().speechModel : preferences.read().cleanupModel
        switch choice {
        case .recommended:
            return fallback
        case .model(let id):
            return library.entries(stage: stage).first { $0.id == id } ?? fallback
        }
    }
}
