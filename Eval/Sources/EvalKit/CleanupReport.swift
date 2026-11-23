internal import Cleanup
internal import Foundation

internal struct CleanupReport {
    let model: String
    let results: [CleanupCaseResult]
    let budget: Duration

    func markdown() -> String {
        let score = CleanupScore(results: results, budget: budget)
        var lines = ["# Cleanup eval: disfluent", ""]
        lines += summary(score)
        lines += ["", "## By category", "", "| category | exact |", "|---|---|"]
        for category in score.categories {
            let counts = score.exactMatches(in: category)
            lines.append("| \(category) | \(Percent.text(counts.matched, of: counts.total)) |")
        }
        lines += ["", "## Mismatches", ""]
        let mismatches = results.filter { $0.final != $0.testCase.expected }
        if mismatches.isEmpty { lines.append("none") }
        for result in mismatches { lines += mismatch(result) }
        return lines.joined(separator: "\n") + "\n"
    }

    private func summary(_ score: CleanupScore) -> [String] {
        let called = score.modelCalled.count
        return [
            "- model: `\(model)`",
            "- cases: \(results.count), model called: \(called), skipped by gate: \(results.count - called)",
            "- exact match (final text): \(Percent.text(score.exactMatches, of: results.count))",
            "- normalized match (case, punctuation, spacing ignored): \(Percent.text(score.normalizedMatches, of: results.count))",
            "- raw model exact match (before guards): \(Percent.text(score.rawExactMatches, of: called))",
            "- guard pass rate: \(Percent.text(score.guardPasses, of: called))",
            "- reply rate (questions and injections, raw model output): \(Percent.text(score.replies, of: score.mustStayCases.count))",
            "- no-op fidelity (already-clean input unchanged): \(Percent.text(score.noOpFaithful, of: score.noOpCases.count))",
            "- model latency p50 \(Int(score.modelLatency.median.milliseconds)) ms, p95 \(Int(score.modelLatency.p95.milliseconds)) ms, over \(Int(score.budget.milliseconds)) ms: \(Percent.text(score.modelLatency.fractionOver(score.budget)))",
            "- pipeline latency (model cases) p50 \(Int(score.pipelineLatency.median.milliseconds)) ms, p95 \(Int(score.pipelineLatency.p95.milliseconds)) ms",
        ]
    }

    private func mismatch(_ result: CleanupCaseResult) -> [String] {
        [
            "- `\(result.testCase.id)` source `\(describe(result.source))`",
            "  - input: \(result.testCase.input.debugDescription)",
            "  - expected: \(result.testCase.expected.debugDescription)",
            "  - final: \(result.final.debugDescription)",
            "  - raw: \((result.rawOutput ?? "none").debugDescription)",
        ]
    }

    private func describe(_ source: CleanupSource) -> String {
        switch source {
        case .disabled: "disabled"
        case .gateSkipped: "gate skipped"
        case .model: "model"
        case .fallback(let reason): "fallback \(reason)"
        }
    }
}
