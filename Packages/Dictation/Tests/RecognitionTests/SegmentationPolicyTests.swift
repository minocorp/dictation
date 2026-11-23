@testable import Recognition
import Testing

internal struct SegmentationPolicyTests {
    private static let frame = SegmentationConfiguration.samples(milliseconds: 20)

    private func run(
        _ pieces: [SyntheticAudio.Piece],
        probabilities: [Float]? = nil,
    ) -> (cuts: [SegmentationPolicy.Cut], last: SegmentationPolicy.Cut?) {
        var policy = SegmentationPolicy()
        let audio = SyntheticAudio.samples(pieces)
        let speechFlags = pieces.flatMap { piece in
            Array(repeating: piece.isSpeech, count: piece.milliseconds / 20)
        }
        var cuts: [SegmentationPolicy.Cut] = []
        for (index, isSpeech) in speechFlags.enumerated() {
            let start = index * Self.frame
            cuts += policy.append(
                frame: Array(audio[start..<start + Self.frame]),
                startSample: start,
                probability: probabilities?[index] ?? (isSpeech ? 0.9 : 0.05),
            )
        }
        return (cuts, policy.finish())
    }

    private func samples(_ milliseconds: Int) -> Int {
        SegmentationConfiguration.samples(milliseconds: milliseconds)
    }

    @Test
    func silenceShorterThanSixHundredMillisecondsDoesNotCut() {
        let result = run([.speech(1_000), .silence(580)])
        #expect(result.cuts.isEmpty)
        #expect(result.last != nil)
    }

    @Test
    func silenceOfSixHundredMillisecondsCuts() {
        let result = run([.speech(1_000), .silence(600)])
        #expect(result.cuts.count == 1)
        #expect(result.last == nil)
    }

    @Test
    func cutKeepsOnlyAShortTrailingPad() throws {
        let result = run([.speech(1_000), .silence(1_000)])
        let cut = try #require(result.cuts.first)
        #expect(cut.startSample == 0)
        #expect(cut.audio.count == samples(1_100))
    }

    @Test
    func leadingSilenceIsTrimmedToAShortPad() throws {
        let result = run([.silence(1_000), .speech(1_000), .silence(1_000)])
        let cut = try #require(result.cuts.first)
        #expect(cut.startSample == samples(900))
        #expect(cut.audio.count == samples(1_200))
    }

    @Test
    func pauseShorterThanTheCutStaysInOneSegment() {
        let result = run([.speech(800), .silence(500), .speech(800), .silence(700)])
        #expect(result.cuts.count == 1)
        #expect(result.cuts.first?.audio.count == samples(800 + 500 + 800 + 100))
    }

    @Test
    func utterancesSeparatedByALongPauseBecomeTwoSegments() {
        let result = run([.speech(800), .silence(1_000), .speech(800), .silence(700)])
        #expect(result.cuts.count == 2)
        #expect(result.cuts.last?.startSample == samples(800 + 1_000 - 100))
    }

    @Test(arguments: [(180, false), (200, true), (300, true)])
    func speechShorterThanTwoHundredMillisecondsIsDropped(milliseconds: Int, isKept: Bool) {
        let result = run([.speech(milliseconds), .silence(700)])
        #expect(result.cuts.isEmpty == !isKept)
    }

    @Test
    func shortSpeechAtTheEndOfTheStreamIsDroppedOrKeptByTheSameRule() {
        #expect(run([.speech(180)]).last == nil)
        #expect(run([.speech(200)]).last != nil)
    }

    @Test
    func finishReturnsTheOpenSegmentWithoutTrailingSilence() throws {
        let result = run([.speech(1_000), .silence(300)])
        let last = try #require(result.last)
        #expect(last.audio.count == samples(1_100))
    }

    @Test
    func probabilityBetweenTheThresholdsKeepsSpeechGoing() throws {
        let probabilities =
            [Float](repeating: 0.9, count: 20) + [Float](repeating: 0.4, count: 50)
        let result = run([.speech(400), .silence(1_000)], probabilities: probabilities)
        #expect(result.cuts.isEmpty)
        #expect(try #require(result.last).audio.count == samples(1_400))
    }

    @Test
    func probabilityBetweenTheThresholdsCannotStartSpeech() {
        let result = run([.speech(1_000)], probabilities: [Float](repeating: 0.4, count: 50))
        #expect(result.cuts.isEmpty)
        #expect(result.last == nil)
    }

    @Test
    func continuousSpeechIsCutAtTheQuietestPointNearTenSeconds() throws {
        let probabilities = [Float](repeating: 0.9, count: 603)
        let result = run(
            [.speech(9_000), .silence(60), .speech(3_000)],
            probabilities: probabilities,
        )
        let first = try #require(result.cuts.first)
        #expect(result.cuts.count == 1)
        #expect(first.startSample == 0)
        #expect((samples(9_000)...samples(9_060)).contains(first.audio.count))
        let last = try #require(result.last)
        #expect(last.startSample == first.audio.count)
    }

    @Test
    func unbrokenSpeechNeverProducesASegmentLongerThanTheLimit() {
        let probabilities = [Float](repeating: 0.9, count: 1_750)
        let result = run([.speech(35_000)], probabilities: probabilities)
        let all = result.cuts + (result.last.map { [$0] } ?? [])
        #expect(all.count >= 3)
        #expect(all.allSatisfy { $0.audio.count <= samples(10_000) + 320 })
        #expect(all.map(\.audio.count).reduce(0, +) == samples(35_000))
        var expectedStart = 0
        for cut in all {
            #expect(cut.startSample == expectedStart)
            expectedStart += cut.audio.count
        }
    }
}
