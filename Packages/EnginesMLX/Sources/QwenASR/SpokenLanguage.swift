import Foundation

internal enum SpokenLanguage {
    private static let englishNames = Locale(identifier: "en_US")

    static func name(for languages: [Locale]) -> String? {
        let codes = codes(languages)
        guard codes.count == 1, let code = codes.first else { return nil }
        return englishNames.localizedString(forLanguageCode: code)
    }

    static func primaryName(for languages: [Locale]) -> String? {
        guard let code = languages.first?.language.languageCode?.identifier else { return nil }
        return englishNames.localizedString(forLanguageCode: code)
    }

    static func isAllowed(detected: String?, text: String, languages: [Locale]) -> Bool {
        guard !languages.isEmpty else { return true }
        if let detected, !detected.isEmpty {
            let allowed = Set(
                codes(languages).compactMap { englishNames.localizedString(forLanguageCode: $0) }
                    .map { $0.lowercased() }
            )
            if !allowed.contains(detected.lowercased()) { return false }
        }
        return !hasForeignScript(text, languages: languages)
    }

    private static func codes(_ languages: [Locale]) -> Set<String> {
        Set(languages.compactMap { $0.language.languageCode?.identifier })
    }

    private static func hasForeignScript(_ text: String, languages: [Locale]) -> Bool {
        let allowsCJK = !codes(languages).isDisjoint(with: ["zh", "ja"])
        guard !allowsCJK else { return false }
        return text.unicodeScalars.contains {
            (0x4E00...0x9FFF).contains($0.value) || (0x3400...0x4DBF).contains($0.value)
                || (0x3040...0x30FF).contains($0.value)
        }
    }
}
