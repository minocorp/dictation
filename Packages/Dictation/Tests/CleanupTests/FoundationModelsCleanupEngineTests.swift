@testable import Cleanup
import Core
import FoundationModels
import Testing

internal struct FoundationModelsCleanupEngineTests {
    @Test
    func prepareSucceedsOrReportsUnavailable() async {
        let engine = FoundationModelsCleanupEngine(gate: InferenceGate())
        do {
            try await engine.prepare()
        } catch {
            #expect(error == .modelUnavailable)
        }
    }

    @Test
    func guardrailViolationIsRejected() {
        let error = LanguageModelSession.GenerationError.guardrailViolation(
            .init(debugDescription: "blocked")
        )
        #expect(FoundationModelsErrorMap.cleanupError(from: error) == .rejected)
    }

    @Test
    func unsupportedLanguageIsRejected() {
        let error = LanguageModelSession.GenerationError.unsupportedLanguageOrLocale(
            .init(debugDescription: "language")
        )
        #expect(FoundationModelsErrorMap.cleanupError(from: error) == .rejected)
    }

    @Test
    func missingAssetsMeanUnavailableModel() {
        let error = LanguageModelSession.GenerationError.assetsUnavailable(
            .init(debugDescription: "assets")
        )
        #expect(FoundationModelsErrorMap.cleanupError(from: error) == .modelUnavailable)
    }

    @Test
    func rateLimitIsAFailureCode() {
        let error = LanguageModelSession.GenerationError.rateLimited(
            .init(debugDescription: "slow down")
        )
        guard case .failed = FoundationModelsErrorMap.cleanupError(from: error) else {
            Issue.record("expected a failure code")
            return
        }
    }
}
