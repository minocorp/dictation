import Core
import Foundation
@testable import Recognition
import Testing

internal struct SileroIntegrationTests {
    @Test(.enabled(if: SpeechFixture.isSayAvailable))
    func realSpeechWithAPauseIsSplitByTheSileroModel() async throws {
        let model = SileroModel(modelDirectory: nil)
        guard await model.makeScorer() != nil else {
            try Test.cancel("Silero model is not available offline")
        }
        let phrase = try SpeechFixture.spoken("Please open the calendar and show me tomorrow.")
        let audio =
            SpeechFixture.silence(seconds: 0.5) + phrase + SpeechFixture.silence(seconds: 1.5)
            + phrase + SpeechFixture.silence(seconds: 0.5)
        let input = AsyncStream<AudioChunk> { continuation in
            for start in stride(from: 0, to: audio.count, by: 1_600) {
                let end = min(start + 1_600, audio.count)
                continuation.yield(
                    AudioChunk(samples: Array(audio[start..<end]), startSample: start)
                )
            }
            continuation.finish()
        }
        let activity = SileroVoiceActivity()
        var segments: [Segment] = []
        for await segment in activity.segments(of: input, id: DictationID()) {
            segments.append(segment)
        }
        #expect(segments.count == 2)
        #expect(segments.map(\.isFinal) == [false, true])
        let first = try #require(segments.first)
        #expect(first.startSample >= 4_000)
        #expect(first.startSample < 12_000)
        #expect(first.audio.count > phrase.count / 2)
    }

    @Test(.enabled(if: SpeechFixture.isSayAvailable))
    func silenceAloneProducesNoSegmentsWithTheRealModel() async throws {
        let model = SileroModel(modelDirectory: nil)
        guard await model.makeScorer() != nil else {
            try Test.cancel("Silero model is not available offline")
        }
        let audio = SpeechFixture.silence(seconds: 3)
        let input = AsyncStream<AudioChunk> { continuation in
            continuation.yield(AudioChunk(samples: audio, startSample: 0))
            continuation.finish()
        }
        var count = 0
        for await _ in SileroVoiceActivity().segments(of: input, id: DictationID()) { count += 1 }
        #expect(count == 0)
    }
}
