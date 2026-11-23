@testable import EvalKit
import Foundation
import Testing

internal struct ASRScoreTests {
    private func result(reference: String, hypothesis: String) -> ASRClipResult {
        ASRClipResult(
            clip: AudioClip(
                id: "x",
                file: URL(fileURLWithPath: "/tmp/x.wav"),
                reference: reference,
            ),
            hypothesis: hypothesis,
            audioSeconds: 1,
            latency: .milliseconds(10),
        )
    }

    @Test
    func perfectHypothesisHasZeroError() {
        let score = ASRScore(
            results: [result(reference: "안녕, 하세요.", hypothesis: "안녕하세요")],
            set: .fleursKorean,
        )
        #expect(score.rate.errors == 0)
    }

    @Test
    func aLatinWordInsideAnotherWordIsNotKept() {
        let score = ASRScore(
            results: [result(reference: "이 app 좋아", hypothesis: "이 applesauce 좋아")],
            set: .hike,
        )
        #expect(score.latinWordsTotal == 1)
        #expect(score.latinWordsKept == 0)
    }

    @Test
    func aLatinWordFollowedByAKoreanParticleIsKept() {
        let score = ASRScore(
            results: [result(reference: "이 app 좋아", hypothesis: "이 app이 좋아")],
            set: .hike,
        )
        #expect(score.latinWordsKept == 1)
    }

    @Test
    func latinWordsAreCountedAgainstTheReference() {
        let score = ASRScore(
            results: [result(reference: "이 bug 때문에 user 안 좋아", hypothesis: "이 bug 때문에 유저 안 좋아")],
            set: .hike,
        )
        #expect(score.latinWordsTotal == 2)
        #expect(score.latinWordsKept == 1)
    }

    @Test
    func englishNumberWordsMatchDigits() {
        let score = ASRScore(
            results: [
                result(
                    reference: "between one hundred and fifty copies",
                    hypothesis: "Between 150 copies.",
                )
            ],
            set: .fleursEnglish,
        )
        #expect(score.rate.errors == 0)
    }

    @Test
    func scriptAwareRateCountsATransliteratedWordOnce() {
        let score = ASRScore(
            results: [result(reference: "이 bug 때문에", hypothesis: "이 버그 때문에")],
            set: .hike,
        )
        #expect(score.scriptRate.errors == 2)
        #expect(score.scriptRate.referenceLength == 5)
    }
}
