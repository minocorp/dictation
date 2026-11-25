@testable import Cleanup
import Testing

internal struct ScriptTokenTests {
    struct Case: Sendable {
        let input: String
        let expected: [String]
    }

    static let table = [
        Case(input: "useEffect에서", expected: ["useEffect", "에서"]),
        Case(input: "src/hooks/useAuth.ts가", expected: ["src/hooks/useAuth.ts", "가"]),
        Case(input: "Kim.", expected: ["Kim"]),
        Case(input: "let's go", expected: ["let's", "go"]),
        Case(input: "- - ...", expected: []),
        Case(input: "35000 원", expected: ["35000", "원"]),
        Case(input: "café에서", expected: ["café", "에서"]),
        Case(input: "naïve 3×4", expected: ["naïve", "3", "4"]),
    ]

    @Test(arguments: table)
    func splitsByScript(_ example: Case) {
        #expect(example.input.scriptTokens.map(\.text) == example.expected)
    }

    @Test
    func recordsUTF16Offsets() {
        #expect("a 😀 bc".scriptTokens.map(\.offset) == [0, 5])
    }
}
