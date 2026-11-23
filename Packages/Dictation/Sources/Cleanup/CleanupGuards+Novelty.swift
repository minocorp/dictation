import Core
import Foundation

extension CleanupGuards {
    private static let latinNovelRatio = 0.15
    private static let latinMinimumWords = 4
    private static let latinAbsoluteNovel = 3
    private static let latinAbsoluteWords = 10
    private static let hangulNovelRatio = 0.2
    private static let hangulMinimumBigrams = 6
    private static let contractionSuffix = Pattern("'(s|ll|re)$")

    func noveltyFailure(_ context: GuardContext) -> GuardFailure? {
        if hasUnspokenMeridiem(context) { return .unspokenMeridiem }
        if hasNovelLatinWords(context) || hasUnspokenDictionaryWord(context) { return .novelWords }
        return hasNovelSyllables(context) ? .novelSyllables : nil
    }

    private func hasUnspokenDictionaryWord(_ context: GuardContext) -> Bool {
        let input = canonicalizer.normalized(context.canonicalInput)
        let output = canonicalizer.normalized(context.canonicalOutput)
        return context.dictionary.contains { word in
            let spelling = canonicalizer.normalized(word.text)
            guard spelling.count > 2, output.contains(spelling), !input.contains(spelling) else {
                return false
            }
            return !word.soundsLike.contains { input.contains(canonicalizer.normalized($0)) }
        }
    }

    private func hasNovelLatinWords(_ context: GuardContext) -> Bool {
        let known = Set(latinWords(context.inputTokens))
        let dictionary = Set(context.dictionary.map { $0.text.lowercased() })
        let output = latinWords(context.outputTokens)
        let novel = Set(output.filter { !known.contains($0) && !dictionary.contains($0) })
        let ratio = Double(novel.count) / Double(max(1, output.count))
        let isRatioBreached = ratio > Self.latinNovelRatio && output.count >= Self.latinMinimumWords
        let isCountBreached =
            novel.count >= Self.latinAbsoluteNovel && output.count >= Self.latinAbsoluteWords
        return isRatioBreached || isCountBreached
    }

    private func latinWords(_ tokens: [ScriptToken]) -> [String] {
        tokens.filter(\.isTechnicalCandidate)
            .map {
                Self.contractionSuffix.replacing(in: $0.text.lowercased(), with: "")
            }
    }

    private func hasNovelSyllables(_ context: GuardContext) -> Bool {
        let known = Set(syllableUnits(context.inputTokens))
        let output = syllableUnits(context.outputTokens)
        let novelCount = output.filter { !known.contains($0) }.count
        return Double(novelCount) / Double(max(1, output.count)) > Self.hangulNovelRatio
            && output.count >= Self.hangulMinimumBigrams
    }

    private func syllableUnits(_ tokens: [ScriptToken]) -> [String] {
        tokens.filter { $0.script == .hangul }
            .flatMap { token -> [String] in
                let characters = Array(token.text)
                guard characters.count > 1 else { return [token.text] }
                return zip(characters, characters.dropFirst()).map { String([$0, $1]) }
            }
    }

    private func hasUnspokenMeridiem(_ context: GuardContext) -> Bool {
        let spoken = meridiemMarkers(in: context.canonicalInput)
        return !meridiemMarkers(in: context.canonicalOutput).isSubset(of: spoken)
    }

    private func meridiemMarkers(in text: String) -> Set<String> {
        let keys = text.split(whereSeparator: \.isWhitespace)
            .map {
                $0.lowercased().replacingOccurrences(of: ".", with: "")
                    .trimmingCharacters(in: CharacterSet(charactersIn: ",?!…:;\"'()"))
            }
        return Set(keys).intersection(data.unspokenMarkers)
    }
}
