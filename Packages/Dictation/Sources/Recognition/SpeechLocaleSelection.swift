import Foundation

internal enum SpeechLocaleSelection {
    static func firstSupported(
        in languages: [Locale],
        equivalent: @Sendable (Locale) async -> Locale?,
    ) async -> Locale? {
        for language in languages {
            if let supported = await equivalent(language) { return supported }
        }
        return nil
    }
}
