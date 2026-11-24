public import Core
import Foundation

public struct CleanupPipeline<TimeClock: Clock<Duration>>: Sendable {
    let engine: any CleanupEngine
    let clock: TimeClock
    let budget: CleanupBudget
    let chunker: TextChunker
    let rules: CleanupRules
    let guards: CleanupGuards
    let editGuard = EditGuard()
    private let gate: CleanupGate

    public init(
        engine: any CleanupEngine,
        clock: TimeClock,
        budget: CleanupBudget,
        chunker: TextChunker = TextChunker(),
    ) {
        let data = CueData.standard
        self.engine = engine
        self.clock = clock
        self.budget = budget
        self.chunker = chunker
        rules = CleanupRules(data: data)
        guards = CleanupGuards(data: data)
        gate = CleanupGate(data: data, matcher: CueMatcher(data: data))
    }

    public func clean(
        _ transcript: String,
        context: CleanupContext,
        preferences: Preferences,
    ) async throws(CleanupError) -> CleanupResult {
        guard preferences.cleanup else {
            return CleanupResult(text: rules.sanitized(transcript), source: .disabled)
        }
        let ruleText = rules.ruleCleaned(transcript)
        let fallbackText = rules.finished(
            ruleText,
            isFinalSegment: context.isFinalSegment,
            dictionary: context.dictionary,
        )
        let decision = gate.decision(forRuleText: ruleText, contextBefore: context.contextBefore)
        guard decision == .callModel else {
            return CleanupResult(text: fallbackText, source: .gateSkipped)
        }
        let outcome = try await modelText(
            for: rules.fillerFree(transcript),
            context: context,
            languages: preferences.languages,
        )
        switch outcome {
        case .text(let text):
            return CleanupResult(
                text: rules.applyingDictionary(
                    rules.joiningParticles(text),
                    dictionary: context.dictionary,
                ),
                source: .model,
            )
        case .fallback(let reason):
            return CleanupResult(text: fallbackText, source: .fallback(reason))
        }
    }

    private func modelText(
        for input: String,
        context: CleanupContext,
        languages: [Locale],
    ) async throws(CleanupError) -> ModelOutcome {
        let start = clock.now
        var cleaned: [String] = []
        for chunk in chunker.chunks(of: input) {
            if Task.isCancelled { throw .cancelled }
            let remaining = budget.segment - start.duration(to: clock.now)
            guard remaining > .zero else { return .fallback(.timedOut) }
            let request = CleanupRequest(
                text: chunk,
                dictionary: context.dictionary,
                contextBefore: ([context.contextBefore] + cleaned).joined(separator: " "),
                languages: languages,
            )
            switch try await attempt(
                budget: remaining,
                work: { [engine] () async throws(CleanupError) -> String in
                    try await engine.clean(request)
                },
            ) {
            case .output(let text):
                if let failure = guards.verify(
                    input: chunk,
                    output: text,
                    dictionary: context.dictionary,
                ) {
                    return .fallback(.guardFailed(failure))
                }
                cleaned.append(text)
            case .timedOut:
                return .fallback(.timedOut)
            case .failed(let error):
                return .fallback(.engine(error))
            }
        }
        return .text(cleaned.joined(separator: " "))
    }
}
