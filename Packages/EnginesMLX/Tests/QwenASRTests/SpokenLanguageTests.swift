import Foundation
@testable import QwenASR
import Testing

internal struct SpokenLanguageTests {
    struct Case: Sendable {
        let identifiers: [String]
        let expected: String?
    }

    static let cases = [
        Case(identifiers: ["ko-KR"], expected: "Korean"),
        Case(identifiers: ["en-US"], expected: "English"),
        Case(identifiers: ["en-US", "en-GB"], expected: "English"),
        Case(identifiers: ["ko-KR", "en-US"], expected: nil),
        Case(identifiers: [], expected: nil),
    ]

    @Test(arguments: cases)
    func languageNameIsOnlyGivenForOneLanguage(_ example: Case) {
        let locales = example.identifiers.map { Locale(identifier: $0) }
        #expect(SpokenLanguage.name(for: locales) == example.expected)
    }

    struct Validation: Sendable {
        let detected: String?
        let text: String
        let identifiers: [String]
        let expected: Bool
    }

    static let validations = [
        Validation(detected: "Korean", text: "꽂았어", identifiers: ["ko", "en"], expected: true),
        Validation(detected: "English", text: "hello", identifiers: ["ko", "en"], expected: true),
        Validation(detected: "Chinese", text: "我想说。", identifiers: ["ko", "en"], expected: false),
        Validation(detected: nil, text: "我想说。", identifiers: ["ko", "en"], expected: false),
        Validation(detected: nil, text: "これは", identifiers: ["ko", "en"], expected: false),
        Validation(detected: "Chinese", text: "我想说。", identifiers: [], expected: true),
        Validation(detected: "Chinese", text: "我想说。", identifiers: ["zh"], expected: true),
        Validation(detected: nil, text: "리액트 React", identifiers: ["ko", "en"], expected: true),
    ]

    @Test(arguments: validations)
    func outputOutsideTheConfiguredLanguagesIsRejected(_ example: Validation) {
        let locales = example.identifiers.map { Locale(identifier: $0) }
        let allowed = SpokenLanguage.isAllowed(
            detected: example.detected,
            text: example.text,
            languages: locales,
        )
        #expect(allowed == example.expected)
    }

    @Test
    func primaryLanguageIsTheFirstConfiguredOne() {
        let locales = [Locale(identifier: "ko-KR"), Locale(identifier: "en-US")]
        #expect(SpokenLanguage.primaryName(for: locales) == "Korean")
        #expect(SpokenLanguage.primaryName(for: []) == nil)
    }
}
