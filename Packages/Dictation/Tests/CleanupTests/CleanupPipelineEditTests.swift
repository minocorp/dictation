@testable import Cleanup
import Clocks
import Core
import CoreTesting
import Foundation
import Testing

internal struct CleanupPipelineEditTests {
    private let engine = FakeCleanupEngine()

    private func pipeline(engine: any CleanupEngine) -> CleanupPipeline<CoreTesting.TestClock> {
        CleanupPipeline(
            engine: engine,
            clock: CoreTesting.TestClock(),
            budget: .recommended(for: .ram16),
        )
    }

    @Test
    func editReturnsAcceptedText() async throws {
        engine.editResult = .success("Hi.")
        let outcome = try await pipeline(engine: engine)
            .edit(
                selection: "Hello there.",
                instruction: "um shorter",
            )
        #expect(outcome == .edited("Hi."))
        #expect(
            engine.editRequests == [
                EditRequest(
                    selection: "Hello there.",
                    instruction: "shorter",
                    timeBudget: .seconds(5),
                )
            ]
        )
    }

    @Test
    func editGuardFailureLeavesSelectionUntouched() async throws {
        engine.editResult = .success("Sure, here you go: Hi.")
        let outcome = try await pipeline(engine: engine)
            .edit(
                selection: "Hello there.",
                instruction: "shorter",
            )
        #expect(outcome == .unchanged(.guardFailed(.replyPattern)))
    }

    @Test
    func editEngineErrorLeavesSelectionUntouched() async throws {
        engine.editResult = .failure(.rejected)
        let outcome = try await pipeline(engine: engine)
            .edit(
                selection: "Hello there.",
                instruction: "shorter",
            )
        #expect(outcome == .unchanged(.engine(.rejected)))
    }

    @Test
    func editTimeoutLeavesSelectionUntouched() async throws {
        let pipeline = CleanupPipeline(
            engine: HangingCleanupEngine(),
            clock: ImmediateClock<Duration>(),
            budget: .recommended(for: .ram16),
        )
        let outcome = try await pipeline.edit(selection: "Hello there.", instruction: "shorter")
        #expect(outcome == .unchanged(.timedOut))
    }
}
