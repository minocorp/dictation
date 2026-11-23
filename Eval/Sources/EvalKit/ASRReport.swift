internal import Foundation

internal struct ASRReport {
    let set: AudioSet
    let model: String
    let results: [ASRClipResult]

    func markdown() -> String {
        let score = ASRScore(results: results, set: set)
        let latencies = LatencyStats(samples: results.map(\.latency))
        let audio = results.reduce(0) { $0 + $1.audioSeconds }
        let compute = results.reduce(0) { $0 + $1.latency.milliseconds } / 1000
        let metric = set.errorUnit == .character ? "CER" : "WER"
        var lines = [
            "# ASR eval: \(set.rawValue)",
            "",
            "- model: `\(model)`",
            "- clips: \(results.count), audio \(String(format: "%.1f", audio)) s",
            "- \(metric): \(Percent.text(score.rate.fraction)) (\(score.rate.errors)/\(score.rate.referenceLength))",
            "- real-time factor: \(String(format: "%.3f", audio > 0 ? compute / audio : 0))",
            "- latency p50 \(Int(latencies.median.milliseconds)) ms, p95 \(Int(latencies.p95.milliseconds)) ms",
        ]
        lines.append("- outputs with Han or kana: \(score.foreignScriptOutputs)/\(results.count)")
        lines.append("- outputs without Hangul: \(score.outputsWithoutHangul)/\(results.count)")
        if set == .hike, score.latinWordsTotal > 0 {
            lines.append(
                "- script-aware CER (Hangul syllables and Latin words as units): \(Percent.text(score.scriptRate.fraction)) (\(score.scriptRate.errors)/\(score.scriptRate.referenceLength))"
            )
            lines.append("- Latin words kept: \(score.latinWordsKept)/\(score.latinWordsTotal)")
        }
        lines += [
            "",
            "Scoring: NFKC, lowercase, punctuation removed, thousands separators removed"
                + (set.normalizationLanguage == .english ? ", English number words to digits" : "")
                + ". Digits versus spelled-out numbers count as errors for Korean; HiKE references keep English words in Latin script, so Hangul transliterations count as errors.",
            "",
            "| clip | sec | ms | reference | hypothesis |",
            "|---|---|---|---|---|",
        ]
        for result in results {
            lines.append(
                "| \(result.clip.id) | \(String(format: "%.1f", result.audioSeconds)) | \(Int(result.latency.milliseconds)) | \(escaped(result.clip.reference)) | \(escaped(result.hypothesis)) |"
            )
        }
        return lines.joined(separator: "\n") + "\n"
    }

    private func escaped(_ text: String) -> String {
        text.replacingOccurrences(of: "|", with: "\\|").replacingOccurrences(of: "\n", with: " ")
    }
}
