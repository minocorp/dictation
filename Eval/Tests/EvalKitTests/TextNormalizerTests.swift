@testable import EvalKit
import Testing

internal struct TextNormalizerTests {
    struct Case: Sendable {
        let language: TextNormalizer.Language
        let input: String
        let expected: String
    }

    static let cases = [
        Case(language: .english, input: "Hello, World!", expected: "hello world"),
        Case(
            language: .english,
            input: "It costs 1,200 dollars.",
            expected: "it costs 1200 dollars",
        ),
        Case(language: .english, input: "between one hundred and fifty", expected: "between 150"),
        Case(language: .english, input: "twenty one apples", expected: "21 apples"),
        Case(language: .english, input: "two thousand twenty five", expected: "2025"),
        Case(language: .english, input: "one hundred and apples", expected: "100 and apples"),
        Case(language: .english, input: "between 150 and 200", expected: "between 150 and 200"),
        Case(language: .korean, input: "일본의 핵, 관련 정부.", expected: "일본의 핵 관련 정부"),
        Case(language: .korean, input: "Ｔｅｓｔ １２３", expected: "test 123"),
        Case(language: .korean, input: "35,000원", expected: "35000원"),
        Case(language: .korean, input: "one two", expected: "one two"),
    ]

    @Test(arguments: cases)
    func normalizesPerLanguage(_ example: Case) {
        #expect(
            TextNormalizer(language: example.language).normalized(example.input) == example.expected
        )
    }
}
