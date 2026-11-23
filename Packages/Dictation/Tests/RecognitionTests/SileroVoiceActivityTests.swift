import Core
@testable import Recognition
import Testing

internal struct SileroVoiceActivityTests {
    private let energyScorer = FrameScorer { frame in
        frame.contains { abs($0) > 0.1 } ? 0.95 : 0.02
    }

    private func segments(
        _ pieces: [SyntheticAudio.Piece],
        scorer: FrameScorer?,
        chunkSize: Int = 1_000,
        id: DictationID = DictationID(),
    ) async -> [Segment] {
        let activity = SileroVoiceActivity(configuration: .standard) { scorer }
        let chunks = SyntheticAudio.chunks(SyntheticAudio.samples(pieces), size: chunkSize)
        let input = AsyncStream<AudioChunk> { continuation in
            for chunk in chunks { continuation.yield(chunk) }
            continuation.finish()
        }
        var result: [Segment] = []
        for await segment in activity.segments(of: input, id: id) {
            result.append(segment)
        }
        return result
    }

    @Test
    func pauseSplitsSegmentsAndOnlyTheLastIsFinal() async {
        let id = DictationID()
        let result = await segments(
            [.speech(1_000), .silence(1_500), .speech(600)],
            scorer: energyScorer,
            id: id,
        )
        #expect(result.map(\.index) == [0, 1])
        #expect(result.map(\.isFinal) == [false, true])
        #expect(result.allSatisfy { $0.dictation == id })
        #expect(result[0].startSample == 0)
        #expect(result[1].startSample > SegmentationConfiguration.samples(milliseconds: 2_000))
    }

    @Test
    func chunkSizeDoesNotChangeTheSegments() async {
        let pieces: [SyntheticAudio.Piece] = [.speech(1_000), .silence(1_500), .speech(600)]
        let id = DictationID()
        let small = await segments(pieces, scorer: energyScorer, chunkSize: 160, id: id)
        let large = await segments(pieces, scorer: energyScorer, chunkSize: 9_000, id: id)
        #expect(small == large)
    }

    @Test
    func silenceOnlyProducesNoSegments() async {
        #expect(await segments([.silence(3_000)], scorer: energyScorer).isEmpty)
    }

    @Test
    func missingModelKeepsAllAudioInOneFinalSegment() async {
        let pieces: [SyntheticAudio.Piece] = [.speech(500), .silence(2_000), .speech(500)]
        let result = await segments(pieces, scorer: nil)
        #expect(result.count == 1)
        #expect(result.first?.isFinal == true)
        #expect(result.first?.audio.count == SyntheticAudio.samples(pieces).count)
    }

    @Test
    func emptyStreamFinishesWithoutSegments() async {
        #expect(await segments([], scorer: energyScorer).isEmpty)
    }
}
