@testable import Cleanup
import Testing

internal struct OutputParserTests {
    struct Case: Sendable {
        let name: String
        let raw: String
        let tag: OutputTag
        let reachedLimit: Bool
        let expected: ParsedOutput?
    }

    private let parser = OutputParser()

    static let table = [
        Case(
            name: "prefilled output with closing tag",
            raw: "Hello world.</cleaned>",
            tag: .cleaned,
            reachedLimit: false,
            expected: ParsedOutput(text: "Hello world.", hasClosingTag: true),
        ),
        Case(
            name: "full block",
            raw: "<cleaned>Hello world.</cleaned>",
            tag: .cleaned,
            reachedLimit: false,
            expected: ParsedOutput(text: "Hello world.", hasClosingTag: true),
        ),
        Case(
            name: "text after the closing tag is ignored",
            raw: "<cleaned>One.</cleaned> Sure, anything else?",
            tag: .cleaned,
            reachedLimit: false,
            expected: ParsedOutput(text: "One.", hasClosingTag: true),
        ),
        Case(
            name: "echoed opening tags",
            raw: "<cleaned><cleaned>One.</cleaned>",
            tag: .cleaned,
            reachedLimit: false,
            expected: ParsedOutput(text: "One.", hasClosingTag: true),
        ),
        Case(
            name: "missing closing tag uses whole output",
            raw: "<cleaned>One. Two.",
            tag: .cleaned,
            reachedLimit: false,
            expected: ParsedOutput(text: "One. Two.", hasClosingTag: false),
        ),
        Case(
            name: "no tag at all",
            raw: "  One. Two.\n",
            tag: .cleaned,
            reachedLimit: false,
            expected: ParsedOutput(text: "One. Two.", hasClosingTag: false),
        ),
        Case(
            name: "empty block is valid",
            raw: "<cleaned></cleaned>",
            tag: .cleaned,
            reachedLimit: false,
            expected: ParsedOutput(text: "", hasClosingTag: true),
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
            expected: ParsedOutput(text: "One.", hasClosingTag: true),
        ),
        Case(
            name: "edit tag",
            raw: "Short.</edited>",
            tag: .edited,
            reachedLimit: false,
            expected: ParsedOutput(text: "Short.", hasClosingTag: true),
        ),
        Case(
            name: "keeps newlines inside",
            raw: "A\n\nB</cleaned>",
            tag: .cleaned,
            reachedLimit: false,
            expected: ParsedOutput(text: "A\n\nB", hasClosingTag: true),
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
