@testable import EvalKit
import Testing

internal struct ErrorRateTests {
    @Test
    func characterErrorRateIgnoresSpaces() {
        var rate = ErrorRate()
        rate.add(reference: "안녕 하세요", hypothesis: "안녕하세오", unit: .character)
        #expect(rate.errors == 1)
        #expect(rate.referenceLength == 5)
        #expect(rate.fraction == 0.2)
    }

    @Test
    func wordErrorRateCountsSubstitutionsInsertionsAndDeletions() {
        var rate = ErrorRate()
        rate.add(reference: "the cat sat", hypothesis: "the big dog sat", unit: .word)
        #expect(rate.errors == 2)
        #expect(rate.referenceLength == 3)
    }

    @Test
    func rateAccumulatesAcrossClips() {
        var rate = ErrorRate()
        rate.add(reference: "a b", hypothesis: "a b", unit: .word)
        rate.add(reference: "c d", hypothesis: "c x", unit: .word)
        #expect(rate.fraction == 0.25)
    }

    @Test
    func emptyReferenceCountsOnlyInsertions() {
        #expect(SequenceDistance.levenshtein([String](), ["a", "b"]) == 2)
        #expect(SequenceDistance.levenshtein(["a"], [String]()) == 1)
    }
}
