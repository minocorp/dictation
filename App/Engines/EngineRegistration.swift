import Core
import ModelCatalog
import QwenASR
import QwenCleanup

internal enum EngineRegistration {
    static func registerDownloadableEngines(in registry: EngineRegistry, gate: InferenceGate) {
        QwenASREngine.register(in: registry, gate: gate)
        QwenCleanupEngine.register(in: registry, gate: gate)
    }
}
