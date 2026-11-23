import Core

extension CleanupGuards {
    private static let maximumExcusedElements = 3

    func retentionFailure(_ context: GuardContext) -> GuardFailure? {
        numberFailure(context) ?? technicalTokenFailure(context)
    }

    private func numberFailure(_ context: GuardContext) -> GuardFailure? {
        let input = numbers(in: context.inputTokens)
        let output = numbers(in: context.outputTokens)
        let inputValues = Set(input.map(\.text))
        if output.contains(where: { !inputValues.contains($0.text) }) { return .inventedNumber }
        var unmatched = output.map(\.text)
        var missing: [ScriptToken] = []
        for token in input {
            if let index = unmatched.firstIndex(of: token.text) {
                unmatched.remove(at: index)
            } else {
                missing.append(token)
            }
        }
        let itemCount = listItemCount(in: context.output)
        if itemCount >= 2, missing.count <= itemCount { return nil }
        return isExcused(missing, in: context) ? nil : .missingNumber
    }

    private func listItemCount(in text: String) -> Int {
        Pattern("^\\s*\\d+[.)]\\s", multiline: true).matches(in: text).count
    }

    private func technicalTokenFailure(_ context: GuardContext) -> GuardFailure? {
        let outputTexts = Set(context.outputTokens.filter { $0.script == .latin }.map(\.text))
        let required = technicalTokens(in: context)
        let missing = required.filter {
            !isRetained($0, outputTexts: outputTexts, context: context)
        }
        return isExcused(missing, in: context) ? nil : .missingTechnicalToken
    }

    private func technicalTokens(in context: GuardContext) -> [ScriptToken] {
        var seen = Set<String>()
        return context.inputTokens.filter { token in
            token.isTechnicalCandidate && (token.isTechnicalByShape || context.isHangulHeavy)
                && seen.insert(token.text).inserted
        }
    }

    private func isRetained(
        _ token: ScriptToken,
        outputTexts: Set<String>,
        context: GuardContext,
    ) -> Bool {
        if isSoundAlikeOfRetainedWord(token, outputTexts: outputTexts, context: context) {
            return true
        }
        guard token.isIdentifierLike else {
            return outputTexts.contains { $0.lowercased() == token.text.lowercased() }
        }
        if outputTexts.contains(token.text) { return true }
        return context.dictionaryTexts.contains {
            $0.lowercased() == token.text.lowercased() && outputTexts.contains($0)
        }
    }

    private func isSoundAlikeOfRetainedWord(
        _ token: ScriptToken,
        outputTexts: Set<String>,
        context: GuardContext,
    ) -> Bool {
        context.dictionary.contains { word in
            outputTexts.contains(word.text)
                && word.soundsLike.contains { phrase in
                    phrase.lowercased().split(whereSeparator: \.isWhitespace)
                        .contains { $0 == token.text.lowercased() }
                }
        }
    }

    private func numbers(in tokens: [ScriptToken]) -> [ScriptToken] {
        tokens.indices
            .filter { index in
                guard tokens[index].isNumber else { return false }
                guard index + 1 < tokens.count, tokens[index + 1].script == .hangul else {
                    return true
                }
                return !tokens[index + 1].text.hasPrefix("번째")
                    && !tokens[index + 1].text.hasPrefix("째")
            }
            .map { tokens[$0] }
    }

    private func isExcused(_ missing: [ScriptToken], in context: GuardContext) -> Bool {
        if missing.isEmpty { return true }
        guard let cueEnd = context.lastCueEnd, missing.count <= Self.maximumExcusedElements else {
            return false
        }
        return missing.allSatisfy { token in
            let first = context.inputTokens.first { $0.text == token.text }?.offset ?? token.offset
            return first < cueEnd
        }
    }
}
