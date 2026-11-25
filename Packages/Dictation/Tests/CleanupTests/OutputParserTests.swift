@testable import Cleanup
import Testing

internal struct OutputParserTests {
    struct Case: Sendable {
        let name: String
        let raw: String
        let tag: OutputTag
        let reachedLimit: Bool
        let expected: String?
    }

    private let parser = OutputParser()

    static let table = [
        Case(
            name: "prefilled output with closing tag",
            raw: "Hello world.</cleaned>",
            tag: .cleaned,
            reachedLimit: false,
            expected: "Hello world.",
        ),
        Case(
            name: "full block",
            raw: "<cleaned>Hello world.</cleaned>",
            tag: .cleaned,
            reachedLimit: false,
            expected: "Hello world.",
        ),
        Case(
            name: "text after the closing tag is ignored",
            raw: "<cleaned>One.</cleaned> Sure, anything else?",
            tag: .cleaned,
            reachedLimit: false,
            expected: "One.",
        ),
        Case(
            name: "echoed opening tags",
            raw: "<cleaned><cleaned>One.</cleaned>",
            tag: .cleaned,
            reachedLimit: false,
            expected: "One.",
        ),
        Case(
            name: "missing closing tag uses whole output",
            raw: "<cleaned>One. Two.",
            tag: .cleaned,
            reachedLimit: false,
            expected: "One. Two.",
        ),
        Case(
            name: "no tag at all",
            raw: "  One. Two.\n",
            tag: .cleaned,
            reachedLimit: false,
            expected: "One. Two.",
        ),
        Case(
            name: "empty block is valid",
            raw: "<cleaned></cleaned>",
            tag: .cleaned,
            reachedLimit: false,
            expected: "",
        ),
        Case(name: "nothing", raw: "  \n", tag: .cleaned, reachedLimit: false, expected: nil),
        Case(
            name: "opening tag only",
            raw: "<cleaned>",
            tag: .cleaned,
            reachedLimit: false,
            expected: nil,
        ),
        Case(
            name: "token limit without closing tag",
            raw: "<cleaned>One. Two",
            tag: .cleaned,
            reachedLimit: true,
            expected: nil,
        ),
        Case(
            name: "token limit with closing tag is fine",
            raw: "One.</cleaned>",
            tag: .cleaned,
            reachedLimit: true,
            expected: "One.",
        ),
        Case(
            name: "edit tag",
            raw: "Short.</edited>",
            tag: .edited,
            reachedLimit: false,
            expected: "Short.",
        ),
        Case(
            name: "keeps newlines inside",
            raw: "A\n\nB</cleaned>",
            tag: .cleaned,
            reachedLimit: false,
            expected: "A\n\nB",
        ),
    ]

    @Test(arguments: table)
    func parses(_ example: Case) {
        let parsed = parser.parse(
            example.raw,
            tag: example.tag,
            reachedTokenLimit: example.reachedLimit,
        )
        #expect(parsed == example.expected, "\(example.name)")
    }
}
