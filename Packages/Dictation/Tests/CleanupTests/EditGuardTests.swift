@testable import Cleanup
import Testing

internal struct EditGuardTests {
    struct Case: Sendable {
        let selection: String
        let output: String
        let isAccepted: Bool
    }

    private let editGuard = EditGuard()

    static let table = [
        Case(selection: "Hello there.", output: "Hi.", isAccepted: true),
        Case(selection: "Hello there.", output: "  ", isAccepted: false),
        Case(
            selection: "Hello there.",
            output: "Sure, here is a shorter one: Hi.",
            isAccepted: false,
        ),
        Case(selection: "Sure thing, see you.", output: "Sure thing, bye.", isAccepted: true),
        Case(selection: "네 알겠습니다", output: "네, 알겠습니다.", isAccepted: true),
        Case(selection: "text", output: "네, 알겠습니다.", isAccepted: false),
        Case(selection: "text", output: "<edited>x", isAccepted: false),
        Case(selection: "text", output: "see <selection> tag", isAccepted: false),
        Case(selection: "text", output: "```\ncode\n```", isAccepted: false),
        Case(selection: "```\ncode\n```", output: "```\nother\n```", isAccepted: true),
        Case(selection: "ab", output: String(repeating: "x", count: 408), isAccepted: true),
        Case(selection: "ab", output: String(repeating: "x", count: 409), isAccepted: false),
    ]

    @Test(arguments: table)
    func verifies(_ example: Case) {
        let failure = editGuard.verify(selection: example.selection, output: example.output)
        #expect((failure == nil) == example.isAccepted)
    }
}
