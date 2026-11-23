import Cleanup
import Core
import Foundation
import Session

internal struct EngineCleanupPipeline: Session.CleanupPipeline {
    let resolver: EngineResolver
    let preferences: PreferencesStore
    let budget: CleanupBudget

    func clean(_ input: CleanInput, dictionary: [Word]) async throws(CleanupError) -> String {
        let result = try await makePipeline()
            .clean(
                input.text,
                context: CleanupContext(
                    dictionary: dictionary,
                    contextBefore: input.contextBefore,
                    isFinalSegment: input.isFinalSegment,
                ),
                preferences: preferences.read(),
            )
        TimingLog.mark("cleanup-source", "source=\(String(describing: result.source))")
        return result.text
    }

    func edit(selection: String, instruction: String) async throws(CleanupError) -> String {
        let outcome = try await makePipeline().edit(selection: selection, instruction: instruction)
        switch outcome {
        case .edited(let text): return text
        case .unchanged: throw .rejected
        }
    }

    private func makePipeline() -> Cleanup.CleanupPipeline<ContinuousClock> {
        Cleanup.CleanupPipeline(
            engine: ResolvedCleanupEngine(resolver: resolver),
            clock: ContinuousClock(),
            budget: budget,
        )
    }
}
