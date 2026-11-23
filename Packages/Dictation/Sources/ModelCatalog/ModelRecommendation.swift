import Core
import Foundation

internal enum ModelRecommendation {
    static func tier(ramGB: Int) -> RAMTier {
        RAMTier(ramGB: ramGB)
    }

    static func pick(
        from entries: [ModelEntry],
        profile: MachineProfile,
    ) -> (speech: ModelEntry, cleanup: ModelEntry) {
        let tier = tier(ramGB: profile.ramGB)
        let speech = entries.first { $0.stage == .speech && $0.defaultFor.contains(tier) }
        let cleanup = entries.first { $0.stage == .cleanup && $0.defaultFor.contains(tier) }
        return (
            speech: speech.flatMap { covers($0, languages: profile.languages) ? $0 : nil }
                ?? .appleSpeechAnalyzer,
            cleanup: cleanup ?? .appleFoundationModels,
        )
    }

    static func covers(_ entry: ModelEntry, languages: [Locale]) -> Bool {
        let supported = Set(entry.languages.map { String($0.prefix { $0 != "-" }) })
        return languages.allSatisfy { locale in
            locale.language.languageCode.map { supported.contains($0.identifier) } ?? false
        }
    }
}
