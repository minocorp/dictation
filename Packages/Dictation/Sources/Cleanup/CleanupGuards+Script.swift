extension CleanupGuards {
    private static let minimumLetters = 8
    private static let maximumShareShift = 0.25
    private static let minimumForeignLetters = 3

    func scriptFailure(_ context: GuardContext) -> GuardFailure? {
        let input = LetterScript.counts(in: context.canonicalInput)
        let output = LetterScript.counts(in: context.canonicalOutput)
        let inputTotal = input.values.reduce(0, +)
        guard inputTotal >= Self.minimumLetters else { return nil }
        let outputTotal = output.values.reduce(0, +)
        let inputShares = shares(input, total: inputTotal)
        let outputShares = shares(output, total: outputTotal)
        let changedDominant = dominant(inputShares) != dominant(outputShares)
        let shifted = LetterScript.allCases.contains {
            abs(inputShares[$0, default: 0] - outputShares[$0, default: 0]) > Self.maximumShareShift
        }
        let foreign = LetterScript.allCases.contains {
            input[$0, default: 0] == 0 && output[$0, default: 0] >= Self.minimumForeignLetters
        }
        return changedDominant || shifted || foreign ? .scriptChanged : nil
    }

    private func shares(_ counts: [LetterScript: Int], total: Int) -> [LetterScript: Double] {
        guard total > 0 else { return [:] }
        return counts.mapValues { Double($0) / Double(total) }
    }

    private func dominant(_ shares: [LetterScript: Double]) -> LetterScript? {
        LetterScript.allCases.max { shares[$0, default: 0] < shares[$1, default: 0] }
            .flatMap { shares[$0, default: 0] > 0 ? $0 : nil }
    }
}
