internal enum CorrectionDiff {
    private static let maxOriginalTokens = 3
    private static let minimumAllowedDistance = 2

    private struct Alignment {
        let before: [WordToken]
        let after: [WordToken]
        let middleBefore: [WordToken]
        let middleAfter: [WordToken]
        let hunks: [TokenAlignment.Hunk]
    }

    static func respellings(inserted: String, baseline: String, final: String) -> [Respelling] {
        guard baseline != final, let region = InsertedRegionLocator.locate(inserted, in: baseline),
            let alignment = align(baseline, final)
        else { return [] }
        return alignment.hunks.compactMap { hunk in
            respelling(
                of: hunk,
                before: alignment.middleBefore,
                after: alignment.middleAfter,
                region: region,
            )
        }
    }

    static func retainsBaseline(_ baseline: String, in candidate: String) -> Bool {
        if baseline == candidate { return true }
        guard let alignment = align(baseline, candidate), !alignment.before.isEmpty else {
            return false
        }
        let removed = alignment.hunks.reduce(0) { $0 + $1.removed.count }
        return (alignment.before.count - removed) * 2 >= alignment.before.count
    }

    private static func align(_ baseline: String, _ final: String) -> Alignment? {
        let before = WordToken.tokens(in: baseline)
        let after = WordToken.tokens(in: final)
        let shared = sharedEdges(before.map(\.core), after.map(\.core))
        let middleBefore = Array(before[shared.prefix..<before.count - shared.suffix])
        let middleAfter = Array(after[shared.prefix..<after.count - shared.suffix])
        guard
            let hunks = TokenAlignment.hunks(
                from: middleBefore.map(\.core),
                to: middleAfter.map(\.core),
            )
        else { return nil }
        return Alignment(
            before: before,
            after: after,
            middleBefore: middleBefore,
            middleAfter: middleAfter,
            hunks: hunks,
        )
    }

    private static func respelling(
        of hunk: TokenAlignment.Hunk,
        before: [WordToken],
        after: [WordToken],
        region: Range<String.Index>,
    ) -> Respelling? {
        guard hunk.added.count == 1, (1...maxOriginalTokens).contains(hunk.removed.count) else {
            return nil
        }
        let removed = hunk.removed.map { before[$0] }
        guard removed.allSatisfy({ region.contains($0.range) }) else { return nil }
        let original = removed.map(\.core).joined(separator: " ").lowercased()
        let corrected = after[hunk.added[0]].core
        guard original != corrected.lowercased(), isRespelling(original, as: corrected) else {
            return nil
        }
        return Respelling(original: original, corrected: corrected)
    }

    private static func isRespelling(_ original: String, as corrected: String) -> Bool {
        let squashed = original.filter { $0 != " " }
        let lowered = corrected.lowercased()
        guard lowered.count >= minimumAllowedDistance else { return false }
        let allowed = max(minimumAllowedDistance, max(squashed.count, lowered.count) / 2)
        return WordDistance.levenshtein(squashed, lowered) <= allowed
    }

    private static func sharedEdges(
        _ before: [String],
        _ after: [String],
    ) -> (prefix: Int, suffix: Int) {
        let limit = min(before.count, after.count)
        var prefix = 0
        while prefix < limit, before[prefix] == after[prefix] { prefix += 1 }
        var suffix = 0
        while suffix < limit - prefix,
            before[before.count - 1 - suffix] == after[after.count - 1 - suffix]
        {
            suffix += 1
        }
        return (prefix, suffix)
    }
}
