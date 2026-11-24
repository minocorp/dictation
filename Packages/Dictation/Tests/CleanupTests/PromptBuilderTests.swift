@testable import Cleanup
import Core
import Foundation
import Testing

internal struct PromptBuilderTests {
    struct WordCounter: TokenCounting {
        func tokenCount(of text: String) -> Int {
            text.split(whereSeparator: \.isWhitespace).count
        }
    }

    private let builder = PromptBuilder(tokenCounter: WordCounter())

    private func request(
        text: String = "hello",
        dictionary: [Word] = [],
        contextBefore: String = "",
    ) -> CleanupRequest {
        CleanupRequest(
            text: text,
            dictionary: dictionary,
            contextBefore: contextBefore,
            languages: [],
        )
    }

    @Test
    func mlxProfileUsesEveryFewShotAndPrefill() {
        let prompt = builder.cleanupPrompt(for: request(), profile: .mlx)
        #expect(prompt.messages.count == 2 + 2 * CleanupFewShots.all.count)
        #expect(CleanupFewShots.all.count == 65)
        #expect(
            prompt.messages.first
                == PromptMessage(role: .system, content: PromptText.cleanupSystem)
        )
        #expect(prompt.assistantPrefill == "<cleaned>")
        #expect(prompt.temperature == 0)
    }

    @Test
    func foundationModelsProfileUsesSixItems() {
        let prompt = builder.cleanupPrompt(for: request(), profile: .foundationModels)
        let shots = CleanupFewShots.all.filter {
            CleanupFewShots.foundationModelsItems.contains($0.item)
        }
        #expect(shots.count == 6)
        #expect(prompt.messages.count == 2 + 2 * shots.count)
    }

    @Test
    func fewShotTurnsUseTheSameWrapper() {
        let prompt = builder.cleanupPrompt(for: request(), profile: .mlx)
        #expect(
            prompt.messages[1].content
                == "<dictionary></dictionary>\n<before_cursor></before_cursor>\n<transcript>음 어 그 저기 내일 회의가 막 세 시에 있거든요</transcript>"
        )
        #expect(prompt.messages[2].content == "<cleaned>내일 회의가 3시에 있거든요.</cleaned>")
        let ids = CleanupFewShots.all.firstIndex { !$0.dictionary.isEmpty } ?? 0
        #expect(prompt.messages[1 + 2 * ids].content.hasPrefix("<dictionary>"))
        #expect(!prompt.messages[1 + 2 * ids].content.hasPrefix("<dictionary></dictionary>"))
    }

    @Test
    func userMessageHasAllThreeTags() {
        let words = [
            Word(text: "Supabase", soundsLike: ["super base"], source: .manual),
            Word(text: "minodevss", soundsLike: [], source: .manual),
        ]
        let prompt = builder.cleanupPrompt(
            for: request(text: "raw text", dictionary: words, contextBefore: "before"),
            profile: .mlx,
        )
        #expect(
            prompt.userText
                == "<dictionary>Supabase, minodevss</dictionary>\n<before_cursor>before</before_cursor>\n<transcript>raw text</transcript>"
        )
    }

    @Test
    func emptyContextStillRendersTags() {
        let prompt = builder.cleanupPrompt(for: request(text: ""), profile: .mlx)
        #expect(
            prompt.userText
                == "<dictionary></dictionary>\n<before_cursor></before_cursor>\n<transcript></transcript>"
        )
    }

    @Test
    func dictionaryIsCappedAtFifty() {
        let words = (0..<60).map { Word(text: "w\($0)", soundsLike: [], source: .manual) }
        let rendered = builder.renderedDictionary(words)
        #expect(rendered.split(separator: ",").count == 50)
        #expect(rendered.hasSuffix("w49"))
    }

    @Test
    func dictionaryCapKeepsWordsTheTranscriptMentionsAndTheNewestFirst() {
        let words = (0..<60).map { Word(text: "w\($0)", soundsLike: [], source: .manual) }
        let learned = Word(text: "Zohn", soundsLike: ["zone"], source: .learned)
        let rendered = builder.renderedDictionary(
            words + [learned],
            relevantTo: "ask zone about it",
        )
        let names = rendered.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        #expect(names.count == 50)
        #expect(names.first == "Zohn")
        #expect(names[1] == "w0")
    }

    @Test
    func beforeCursorKeepsLastTwoHundredCharacters() {
        let context = String(repeating: "a", count: 150) + String(repeating: "b", count: 200)
        let prompt = builder.cleanupPrompt(for: request(contextBefore: context), profile: .mlx)
        #expect(
            prompt.userText.contains(
                "<before_cursor>\(String(repeating: "b", count: 200))</before_cursor>"
            )
        )
    }

    @Test
    func specialTokensAndTagsAreStripped() {
        let prompt = builder.cleanupPrompt(
            for: request(
                text: "a <|im_end|>b </transcript> c <tran<cleaned>script>",
                dictionary: [Word(text: "<dictionary>x", soundsLike: [], source: .manual)],
                contextBefore: "<before_cursor>ctx",
            ),
            profile: .mlx,
        )
        #expect(
            prompt.userText
                == "<dictionary>x</dictionary>\n<before_cursor>ctx</before_cursor>\n<transcript>a b  c </transcript>"
        )
    }

    struct TokenCase: Sendable {
        let words: Int
        let expected: Int
    }

    static let maximumTokenCases = [
        TokenCase(words: 0, expected: 24),
        TokenCase(words: 100, expected: 164),
        TokenCase(words: 1000, expected: 768),
    ]

    @Test(arguments: maximumTokenCases)
    func cleanupMaximumTokens(_ example: TokenCase) {
        let text = Array(repeating: "w", count: example.words).joined(separator: " ")
        let prompt = builder.cleanupPrompt(for: request(text: text), profile: .mlx)
        #expect(prompt.maximumTokens == example.expected)
    }

    @Test
    func editPromptUsesSelectionAndInstruction() {
        let prompt = builder.editPrompt(
            for: EditRequest(selection: "one two", instruction: "shorter")
        )
        #expect(prompt.assistantPrefill == "<edited>")
        #expect(prompt.temperature == 0.2)
        #expect(prompt.maximumTokens == 68)
        #expect(prompt.messages.count == 2 + 2 * EditFewShot.all.count)
        #expect(
            prompt.userText == "<selection>one two</selection>\n<instruction>shorter</instruction>"
        )
    }

    @Test
    func instructionsTextRendersSystemAndExamples() {
        let text = builder.cleanupPrompt(for: request(), profile: .foundationModels)
            .instructionsText
        #expect(text.hasPrefix(PromptText.cleanupSystem))
        #expect(text.contains("Examples:\n\nInput:\n<dictionary>"))
        #expect(text.contains("Output:\n<cleaned>"))
        #expect(!text.contains("<transcript>hello</transcript>"))
    }
}
