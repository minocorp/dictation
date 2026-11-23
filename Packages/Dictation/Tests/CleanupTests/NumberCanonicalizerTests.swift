@testable import Cleanup
import Testing

internal struct NumberCanonicalizerTests {
    struct Case: Sendable {
        let input: String
        let expected: String
    }

    private let canonicalizer = TextCanonicalizer()

    static let table = [
        Case(input: "삼만 오천 원", expected: "35000 원"),
        Case(input: "35,000원", expected: "35000 원"),
        Case(input: "삼만 오천 원이고 이십삼 일에", expected: "35000 원이고 23 일에"),
        Case(input: "세 시에", expected: "3 시에"),
        Case(input: "3시에", expected: "3 시에"),
        Case(input: "이천이십육 년", expected: "2026 년"),
        Case(input: "공일공", expected: "010"),
        Case(input: "스물다섯 살", expected: "25 살"),
        Case(input: "서른 세 살", expected: "33 살"),
        Case(input: "열두 개", expected: "12 개"),
        Case(input: "삼십 일 후", expected: "30 일 후"),
        Case(input: "하나", expected: "1"),
        Case(input: "이 사람", expected: "이 사람"),
        Case(input: "사람이 오이", expected: "사람이 오이"),
        Case(input: "이거 서울에서", expected: "이거 서울에서"),
        Case(input: "일 오 사", expected: "일 오 사"),
        Case(input: "첫째 둘째 셋째", expected: "첫째 둘째 셋째"),
        Case(input: "첫 번째 두 번째 세 번째", expected: "첫 번째 두 번째 세 번째"),
        Case(input: "반 쯤 약", expected: "반 쯤 약"),
        Case(input: "three thirty", expected: "3 30"),
        Case(input: "twelve fifty", expected: "12 50"),
        Case(input: "twenty five", expected: "25"),
        Case(input: "one hundred and five", expected: "105"),
        Case(input: "two thousand twenty six", expected: "2026"),
        Case(input: "two oh one", expected: "2 0 1"),
        Case(input: "twelve point five", expected: "12 5"),
        Case(input: "oh no", expected: "oh no"),
        Case(input: "$12.50", expected: "12 50"),
        Case(input: "3:30 pm", expected: "3 30 pm"),
        Case(input: "1.5", expected: "1 5"),
        Case(input: "first second third fifth 5th", expected: "first second third fifth 5th"),
        Case(input: "1. Install\n2. Run", expected: "Install Run"),
    ]

    @Test(arguments: table)
    func canonicalizes(_ example: Case) {
        #expect(canonicalizer.canonicalText(example.input) == example.expected)
    }

    @Test
    func digitsAndWordsCompareEqual() {
        #expect(
            canonicalizer.canonicalText("삼만 오천 원이고 이십삼 일")
                == canonicalizer.canonicalText("35,000원이고 23일")
        )
    }
}
