import Foundation
@testable import Recognition
import Testing

internal struct SpeechLocaleSelectionTests {
    private let supported = [Locale(identifier: "en_US"), Locale(identifier: "ko_KR")]

    private func equivalent(_ locale: Locale) -> Locale? {
        let code = locale.language.languageCode?.identifier
        return supported.first { $0.language.languageCode?.identifier == code }
    }

    @Test
    func firstSupportedLanguageWins() async {
        let languages = [
            Locale(identifier: "fr"), Locale(identifier: "ko"), Locale(identifier: "en"),
        ]
        let selected = await SpeechLocaleSelection.firstSupported(in: languages) { equivalent($0) }
        #expect(selected == Locale(identifier: "ko_KR"))
    }

    @Test
    func noSupportedLanguageGivesNil() async {
        let languages = [Locale(identifier: "fr"), Locale(identifier: "de")]
        let selected = await SpeechLocaleSelection.firstSupported(in: languages) { equivalent($0) }
        #expect(selected == nil)
    }

    @Test
    func emptyLanguageListGivesNil() async {
        let selected = await SpeechLocaleSelection.firstSupported(in: []) { equivalent($0) }
        #expect(selected == nil)
    }
}
