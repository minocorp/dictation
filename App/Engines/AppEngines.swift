import Core
import Foundation
import ModelCatalog

internal struct AppEngines: Sendable {
    let gate: InferenceGate
    let library: ManifestModelLibrary
    let residency: ModelResidency
    let resolver: EngineResolver

    static func make(paths: AppPaths, preferences: PreferencesStore) -> AppEngines {
        let gate = InferenceGate()
        let profile = MachineProfile.current(languages: preferences.read().languages)
        let storage = ModelStorage(root: paths.models)
        let downloader = ModelDownloader(
            storage: storage,
            sessionFactory: .standard,
            availableBytes: { [root = paths.models] in ModelStorage.availableBytes(at: root) },
        )
        let library = ManifestModelLibrary(
            manifest: loadManifest(),
            profile: profile,
            storage: storage,
            downloader: downloader,
        )
        let registry = EngineRegistry()
        EngineRegistration.registerDownloadableEngines(in: registry, gate: gate)
        let residency = ModelResidency(gate: gate, ramGB: profile.ramGB, clock: ContinuousClock())
        let resolver = EngineResolver(
            library: library,
            registry: registry,
            residency: residency,
            gate: gate,
            preferences: preferences,
        )
        return AppEngines(gate: gate, library: library, residency: residency, resolver: resolver)
    }

    private static func loadManifest() -> ModelManifest {
        do {
            return try ModelManifest.bundled()
        } catch {
            AppLog.failure("load model manifest", error)
            return ModelManifest(schemaVersion: 1, models: [])
        }
    }
}
