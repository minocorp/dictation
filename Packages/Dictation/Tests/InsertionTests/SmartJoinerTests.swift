@testable import Insertion
import Testing

internal struct SmartJoinerTests {
    private struct Case: Sendable {
        let name: String
        let before: String?
        let text: String
        let joined: String
    }

    private static let cases = [
        Case(name: "no information", before: nil, text: "hello", joined: "hello"),
        Case(name: "start of field", before: "", text: "  hello", joined: "hello"),
        Case(name: "empty text", before: "Hi", text: "", joined: ""),
        Case(name: "word then word", before: "Hello", text: "world", joined: " world"),
        Case(
            name: "sentence end capitalizes",
            before: "Hello.",
            text: "how are you",
            joined: " How are you",
        ),
        Case(name: "korean sentence end gets a space", before: "잘돼.", text: "리액트", joined: " 리액트"),
        Case(name: "korean question gets a space", before: "알아?", text: "응", joined: " 응"),
        Case(
            name: "korean then english after a period",
            before: "잘돼.",
            text: "okay",
            joined: " Okay",
        ),
        Case(
            name: "english then korean after a period",
            before: "Done.",
            text: "잘돼",
            joined: " 잘돼",
        ),
        Case(name: "korean words without punctuation", before: "리액트", text: "이거", joined: " 이거"),
        Case(name: "question mark capitalizes", before: "Really?", text: "yes", joined: " Yes"),
        Case(name: "trailing space no extra space", before: "Hello. ", text: "how", joined: "How"),
        Case(
            name: "text leading space dropped",
            before: "Hello ",
            text: " world",
            joined: "world",
        ),
        Case(name: "new line capitalizes", before: "line\n", text: "hello", joined: "Hello"),
        Case(
            name: "mid sentence function word",
            before: "I went to",
            text: "The store",
            joined: " the store",
        ),
        Case(
            name: "comma then function word",
            before: "Hello,",
            text: "And then",
            joined: " and then",
        ),
        Case(
            name: "proper noun kept",
            before: "I met",
            text: "Seoul people",
            joined: " Seoul people",
        ),
        Case(name: "pronoun I kept", before: "Then", text: "I left", joined: " I left"),
        Case(name: "acronym kept", before: "Use", text: "The NASA", joined: " the NASA"),
        Case(
            name: "acronym first word kept",
            before: "Use",
            text: "NASA data",
            joined: " NASA data",
        ),
        Case(name: "attaching comma", before: "Hello", text: ", world", joined: ", world"),
        Case(name: "attaching period", before: "Hello", text: ".", joined: "."),
        Case(name: "after open paren", before: "(", text: "see", joined: "see"),
        Case(name: "after hyphen", before: "foo-", text: "bar", joined: "bar"),
        Case(
            name: "after closing quote",
            before: "He said \"hi\"",
            text: "and left",
            joined: " and left",
        ),
        Case(name: "text starts on new line", before: "Hello", text: "\nNext", joined: "\nNext"),
        Case(name: "digits", before: "Price 5", text: "dollars", joined: " dollars"),
        Case(name: "korean sentence", before: "안녕하세요", text: "반갑습니다", joined: " 반갑습니다"),
        Case(name: "korean after period", before: "안녕하세요.", text: "반갑습니다", joined: " 반갑습니다"),
        Case(name: "korean then english", before: "이거", text: "React 써줘", joined: " React 써줘"),
        Case(name: "english then korean", before: "React", text: "이거 해줘", joined: " 이거 해줘"),
        Case(
            name: "korean then english after period",
            before: "좋아요.",
            text: "the end",
            joined: " The end",
        ),
        Case(name: "japanese no space", before: "こんにちは", text: "世界", joined: "世界"),
        Case(name: "japanese after full stop", before: "こんにちは。", text: "元気", joined: "元気"),
        Case(name: "english then japanese", before: "Hello", text: "世界", joined: "世界"),
        Case(name: "ellipsis capitalizes", before: "Well…", text: "okay", joined: " Okay"),
    ]

    @Test(arguments: cases)
    private func joins(testCase: Case) {
        #expect(
            SmartJoiner.join(testCase.text, after: testCase.before) == testCase.joined,
            "\(testCase.name)",
        )
    }
}
