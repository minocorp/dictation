internal import Cleanup
internal import Core
internal import Foundation
internal import QwenCleanup

internal struct CleanupCommand {
    private static let appleModel = "apple"

    let arguments: Arguments
    let root: URL

    func run() async throws(EvalError) -> String {
        let model = try arguments.required("model")
        let set = arguments.value(for: "set") ?? "disfluent"
        guard set == "disfluent" else { throw .usage("unknown cleanup set \(set)") }
        let fixtures =
            arguments.value(for: "fixtures").map { URL(fileURLWithPath: $0) }
            ?? root.appending(path: "Eval/Fixtures/disfluent.jsonl")
        let cases = try CleanupCase.load(from: fixtures)
        let recorder = RecordingCleanupEngine(wrapping: makeEngine(model: model))
        do {
            try await recorder.prepare()
        } catch {
            throw .engine("cannot prepare \(model): \(error)")
        }
        let results = try await evaluate(cases, recorder: recorder)
        await recorder.unload()
        let tier: RAMTier = model == Self.appleModel ? .ram8 : .ram16
        let budget = CleanupBudget.recommended(for: tier).segment
        return CleanupReport(model: model, results: results, budget: budget).markdown()
    }

    private func makeEngine(model: String) -> any CleanupEngine {
        let gate = InferenceGate()
        if model == Self.appleModel { return FoundationModelsCleanupEngine(gate: gate) }
        return QwenCleanupEngine(directory: URL(fileURLWithPath: model), gate: gate)
    }

    private func evaluate(
        _ cases: [CleanupCase],
        recorder: RecordingCleanupEngine,
    ) async throws(EvalError) -> [CleanupCaseResult] {
        let pipeline = CleanupPipeline(
            engine: recorder,
            clock: ContinuousClock(),
            budget: CleanupBudget(segment: .seconds(30), edit: .seconds(30)),
        )
        var results: [CleanupCaseResult] = []
        for testCase in cases {
            let result = try await evaluate(testCase, pipeline: pipeline, recorder: recorder)
            FileHandle.standardError.write(Data("\(testCase.id) \(result.final)\n".utf8))
            results.append(result)
        }
        return results
    }

    private func evaluate(
        _ testCase: CleanupCase,
        pipeline: CleanupPipeline<ContinuousClock>,
        recorder: RecordingCleanupEngine,
    ) async throws(EvalError) -> CleanupCaseResult {
        let context = CleanupContext(
            dictionary: testCase.words,
            contextBefore: testCase.contextBefore,
            isFinalSegment: true,
        )
        let preferences = Preferences.makeDefault(
            globeSwitchesInputSource: false,
            preferredLanguages: [Locale(identifier: "ko"), Locale(identifier: "en")],
        )
        _ = recorder.drain()
        let clock = ContinuousClock()
        let start = clock.now
        let outcome: CleanupResult
        do {
            outcome = try await pipeline.clean(
                testCase.input,
                context: context,
                preferences: preferences,
            )
        } catch {
            throw .engine("\(testCase.id): \(error)")
        }
        let elapsed = start.duration(to: clock.now)
        let calls = recorder.drain()
        return CleanupCaseResult(
            testCase: testCase,
            final: outcome.text,
            source: outcome.source,
            rawOutput: calls.isEmpty ? nil : calls.compactMap(\.output).joined(separator: " "),
            modelDuration: calls.isEmpty ? nil : calls.reduce(.zero) { $0 + $1.duration },
            pipelineDuration: elapsed,
        )
    }
}
