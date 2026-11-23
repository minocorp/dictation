internal import Cleanup
internal import Foundation

internal struct CleanupScore {
    private static let replyDistance = 0.5

    let results: [CleanupCaseResult]
    let budget: Duration
    private let normalizer = TextNormalizer(language: .korean)
    private let replyDetector = ReplyDetector()

    init(results: [CleanupCaseResult], budget: Duration) {
        self.results = results
        self.budget = budget
    }

    var exactMatches: Int { results.count { $0.final == $0.testCase.expected } }

    var normalizedMatches: Int {
        results.count {
            normalizer.normalized($0.final) == normalizer.normalized($0.testCase.expected)
        }
    }

    var modelCalled: [CleanupCaseResult] { results.filter(\.wasModelCalled) }

    var guardPasses: Int { modelCalled.count(where: \.passedGuards) }

    var rawExactMatches: Int {
        modelCalled.count { $0.rawOutput == $0.testCase.expected }
    }

    var mustStayCases: [CleanupCaseResult] { results.filter { $0.testCase.mustStayContent } }

    var replies: Int { mustStayCases.count { isReply($0) } }

    var noOpCases: [CleanupCaseResult] { results.filter { $0.testCase.isNoOp } }

    var noOpFaithful: Int { noOpCases.count { $0.final == $0.testCase.input } }

    var modelLatency: LatencyStats {
        LatencyStats(samples: modelCalled.compactMap(\.modelDuration))
    }

    var pipelineLatency: LatencyStats {
        LatencyStats(samples: modelCalled.map(\.pipelineDuration))
    }

    var categories: [String] {
        var seen: [String] = []
        for result in results where !seen.contains(result.testCase.category) {
            seen.append(result.testCase.category)
        }
        return seen
    }

    func exactMatches(in category: String) -> (matched: Int, total: Int) {
        let members = results.filter { $0.testCase.category == category }
        return (members.count { $0.final == $0.testCase.expected }, members.count)
    }

    private func isReply(_ result: CleanupCaseResult) -> Bool {
        guard let raw = result.rawOutput else { return false }
        let input = result.testCase.input
        if replyDetector.hasReplyOpener(raw, input: input)
            || replyDetector.hasForeignStructure(raw, input: input)
        {
            return true
        }
        var rate = ErrorRate()
        rate.add(
            reference: normalizer.normalized(result.testCase.expected),
            hypothesis: normalizer.normalized(raw),
            unit: .character,
        )
        return rate.fraction > Self.replyDistance
    }
}
