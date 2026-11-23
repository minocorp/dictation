internal import Foundation

internal struct ASRScore {
    let rate: ErrorRate
    let scriptRate: ErrorRate
    let foreignScriptOutputs: Int
    let outputsWithoutHangul: Int
    let latinWordsKept: Int
    let latinWordsTotal: Int

    init(results: [ASRClipResult], set: AudioSet) {
        let normalizer = TextNormalizer(language: set.normalizationLanguage)
        var rate = ErrorRate()
        var scriptRate = ErrorRate()
        var kept = 0
        var foreign = 0
        var withoutHangul = 0
        var total = 0
        for result in results {
            let reference = normalizer.normalized(result.clip.reference)
            let hypothesis = normalizer.normalized(result.hypothesis)
            rate.add(reference: reference, hypothesis: hypothesis, unit: set.errorUnit)
            scriptRate.add(reference: reference, hypothesis: hypothesis, unit: .script)
            if result.hypothesis.unicodeScalars.contains(where: Self.isHanOrKana) { foreign += 1 }
            if !result.hypothesis.unicodeScalars.contains(where: {
                (0xAC00...0xD7A3).contains($0.value)
            }) {
                withoutHangul += 1
            }
            let hypothesisWords = Set(Self.latinRuns(in: hypothesis))
            for word in Self.latinWords(in: reference) {
                total += 1
                if hypothesisWords.contains(word) { kept += 1 }
            }
        }
        self.rate = rate
        foreignScriptOutputs = foreign
        outputsWithoutHangul = withoutHangul
        self.scriptRate = scriptRate
        latinWordsKept = kept
        latinWordsTotal = total
    }

    private static func isHanOrKana(_ scalar: Unicode.Scalar) -> Bool {
        (0x4E00...0x9FFF).contains(scalar.value) || (0x3040...0x30FF).contains(scalar.value)
    }

    private static func latinRuns(in text: String) -> [String] {
        text.unicodeScalars
            .split { !($0.isASCII && $0.properties.isAlphabetic) }
            .map { String(String.UnicodeScalarView($0)) }
    }

    private static func latinWords(in text: String) -> [String] {
        text.split(separator: " ").map(String.init)
            .filter { word in
                word.count > 1
                    && word.unicodeScalars.allSatisfy { $0.isASCII && $0.properties.isAlphabetic }
            }
    }
}
