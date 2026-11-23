@testable import Cleanup
import Testing

internal struct TextChunkerTests {
    struct WordCounter: TokenCounting {
        func tokenCount(of text: String) -> Int {
            text.split(whereSeparator: \.isWhitespace).count
        }
    }

    private func chunker(limit: Int) -> TextChunker {
        TextChunker(counter: WordCounter(), maximumTokens: limit)
    }

    @Test
    func shortTextIsOneChunk() {
        #expect(chunker(limit: 10).chunks(of: "one two three.") == ["one two three."])
    }

    @Test
    func splitsOnSentenceBoundaries() {
        let text = "One two three. Four five six. Seven eight nine."
        #expect(
            chunker(limit: 6).chunks(of: text) == [
                "One two three. Four five six.", "Seven eight nine.",
            ]
        )
    }

    @Test
    func splitsKoreanQuestionsAndNewlines() {
        let text = "오늘 뭐 해? 점심 먹자\n저녁은 어때"
        #expect(chunker(limit: 3).chunks(of: text) == ["오늘 뭐 해?", "점심 먹자", "저녁은 어때"])
    }

    @Test
    func splitsLongSentenceOnWords() {
        let text = "a b c d e f g"
        #expect(chunker(limit: 3).chunks(of: text) == ["a b c", "d e f", "g"])
    }

    @Test
    func chunksRejoinToTheOriginalWords() {
        let text =
            "alpha beta gamma. delta epsilon zeta eta theta. iota kappa lambda mu nu xi omicron"
        let chunks = chunker(limit: 5).chunks(of: text)
        #expect(chunks.joined(separator: " ").split(separator: " ") == text.split(separator: " "))
        #expect(chunks.allSatisfy { WordCounter().tokenCount(of: $0) <= 5 })
    }

    @Test
    func emptyTextHasNoChunks() {
        #expect(chunker(limit: 5).chunks(of: "  ").isEmpty)
    }

    @Test
    func defaultCounterEstimatesLatinAndHangul() {
        let counter = ApproximateTokenCounter()
        #expect(counter.tokenCount(of: "abcdefgh") == 2)
        #expect(counter.tokenCount(of: "안녕하세요") == 5)
    }
}
