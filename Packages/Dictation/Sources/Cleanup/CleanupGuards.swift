import Core
import Foundation

internal struct CleanupGuards: Sendable {
    let data: CueData
    let matcher: CueMatcher
    let rules: CleanupRules
    let canonicalizer = TextCanonicalizer()
    let replyDetector = ReplyDetector()
    let respelling = LatinRespelling()
    let ordinalCue: Pattern
    let listMarker = Pattern.numberedListMarker

    init(data: CueData = .standard) {
        self.data = data
        matcher = CueMatcher(data: data)
        rules = CleanupRules(data: data)
        ordinalCue = Pattern(data.ordinalListCues.all.joined(separator: "|"))
    }

    func verify(input spoken: String, output: String, dictionary: [Word]) -> GuardFailure? {
        let input = respelling.inputApplyingRespellings(input: spoken, output: output)
        let context = makeContext(
            input: input,
            spokenInput: spoken,
            output: output,
            dictionary: dictionary,
        )
        if output.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return isEmptyAcceptable(context) ? nil : .emptyOutput
        }
        let checks: [(GuardContext) -> GuardFailure?] = [
            retentionFailure, leadInFailure, lengthFailure, editDistanceFailure, scriptFailure,
            replyFailure,
            noveltyFailure, leakFailure,
        ]
        for check in checks {
            if let failure = check(context) { return failure }
        }
        return nil
    }

    private func makeContext(
        input: String,
        spokenInput: String,
        output: String,
        dictionary: [Word],
    ) -> GuardContext {
        let canonicalInput = canonicalizer.canonicalText(input)
        let canonicalOutput = canonicalizer.canonicalText(output)
        let correctionEnd = matcher.lastCorrectionEnd(in: canonicalInput)
        return GuardContext(
            input: input,
            spokenInput: spokenInput,
            output: output,
            dictionary: dictionary,
            canonicalInput: canonicalInput,
            canonicalOutput: canonicalOutput,
            normalizedInput: canonicalizer.normalized(canonicalInput),
            normalizedOutput: canonicalizer.normalized(canonicalOutput),
            inputTokens: canonicalInput.scriptTokens,
            outputTokens: canonicalOutput.scriptTokens,
            lastCueEnd: correctionEnd,
            hasAnyCue: correctionEnd != nil || matcher.hasAnyListCue(in: canonicalInput),
        )
    }

    private func isEmptyAcceptable(_ context: GuardContext) -> Bool {
        if context.normalizedInput.isEmpty { return true }
        let fillers = Set(data.unambiguousFillers.all.map { $0.lowercased() })
        return context.canonicalInput.split(whereSeparator: \.isWhitespace)
            .allSatisfy {
                fillers.contains(
                    $0.lowercased().trimmingCharacters(in: CharacterSet(charactersIn: ",.…"))
                )
            }
    }

    private func leadInFailure(_ context: GuardContext) -> GuardFailure? {
        guard listMarker.matches(in: context.output).count >= 2,
            let cue = ordinalCue.matches(in: context.input).first
        else { return nil }
        let leadIn = (context.input as NSString).substring(to: cue.range.location)
        let spoken = canonicalizer.normalized(leadIn)
        guard !spoken.isEmpty else { return nil }
        return canonicalizer.normalized(context.output).contains(spoken) ? nil : .droppedLeadIn
    }

    private func replyFailure(_ context: GuardContext) -> GuardFailure? {
        if replyDetector.hasReplyOpener(context.output, input: context.input) {
            return .replyPattern
        }
        if replyDetector.hasForeignStructure(context.output, input: context.input) {
            return .structureLeak
        }
        return nil
    }

    private func leakFailure(_ context: GuardContext) -> GuardFailure? {
        let isLeak = CleanupFewShots.all.contains { shot in
            canonicalizer.normalized(shot.cleaned) == canonicalizer.normalized(context.output)
                && EditDistance.between(
                    canonicalizer.normalized(shot.transcript),
                    canonicalizer.normalized(context.spokenInput),
                ) > 3
        }
        return isLeak ? .exampleLeak : nil
    }
}
