@testable import Capture
import Core
import Foundation
import Testing

internal struct CapturePipelineTests {
    private struct Harness {
        let scratch: ScratchDirectory
        let url: URL
        let pipeline: CapturePipeline
        let chunks: AsyncStream<AudioChunk>
        let failures: AsyncStream<CaptureError>
        let levels: AsyncStream<Float>
        let levelEnd: AsyncStream<Float>.Continuation

        init() throws {
            scratch = try ScratchDirectory()
            url = scratch.file("p.caf")
            let chunkStream = AsyncStream.makeStream(of: AudioChunk.self)
            let failureStream = AsyncStream.makeStream(of: CaptureError.self)
            let levelStream = AsyncStream.makeStream(
                of: Float.self,
                bufferingPolicy: .bufferingNewest(1),
            )
            chunks = chunkStream.stream
            failures = failureStream.stream
            levels = levelStream.stream
            levelEnd = levelStream.continuation
            pipeline = CapturePipeline(
                writer: try CAFWriter(url: url),
                outputs: CaptureOutputs(
                    chunks: chunkStream.continuation,
                    failures: failureStream.continuation,
                ),
                levels: levelStream.continuation,
            )
        }
    }

    @Test
    func drainedAudioBecomesContiguousChunksAndMatchesTheFile() async throws {
        let harness = try Harness()
        let ring = SPSCRingBuffer(capacity: 48_000 * 2 * 2)
        #expect(harness.pipeline.attach(sampleRate: 48_000, channelCount: 2))
        let tone = Tone.interleaved(frequency: 440, rate: 48_000, channels: 2, seconds: 0.4)
        for block in stride(from: 0, to: tone.count, by: 960) {
            _ = tone[block..<min(block + 960, tone.count)]
                .withUnsafeBufferPointer { ring.write($0) }
            harness.pipeline.drain(ring, channelCount: 2)
        }
        harness.pipeline.detach(ring, channelCount: 2)
        harness.pipeline.finish()

        var samples: [Float] = []
        var expectedStart = 0
        for await chunk in harness.chunks {
            #expect(chunk.startSample == expectedStart)
            expectedStart += chunk.samples.count
            samples += chunk.samples
        }
        #expect(abs(samples.count - 6_400) < 200)
        #expect(try CAFRecovery.samples(at: harness.url) == samples)
        harness.levelEnd.finish()
        var lastLevel: Float?
        for await level in harness.levels { lastLevel = level }
        #expect((lastLevel ?? 0) > 0.3)
    }

    @Test
    func restartOnAnotherRateKeepsTheTimelineAndTheFile() async throws {
        let harness = try Harness()
        let first = SPSCRingBuffer(capacity: 96_000)
        let second = SPSCRingBuffer(capacity: 96_000)
        #expect(harness.pipeline.attach(sampleRate: 48_000, channelCount: 1))
        let toneA = Tone.mono(frequency: 440, rate: 48_000, seconds: 0.3)
        _ = toneA.withUnsafeBufferPointer { first.write($0) }
        harness.pipeline.detach(first, channelCount: 1)
        #expect(harness.pipeline.attach(sampleRate: 16_000, channelCount: 1))
        let toneB = Tone.mono(frequency: 440, rate: 16_000, seconds: 0.2)
        _ = toneB.withUnsafeBufferPointer { second.write($0) }
        harness.pipeline.drain(second, channelCount: 1)
        harness.pipeline.finish()

        var samples: [Float] = []
        var expectedStart = 0
        for await chunk in harness.chunks {
            #expect(chunk.startSample == expectedStart)
            expectedStart += chunk.samples.count
            samples += chunk.samples
        }
        #expect(abs(samples.count - 8_000) < 200)
        #expect(try CAFRecovery.samples(at: harness.url) == samples)
    }

    @Test
    func attachFailsForAnInvalidFormat() throws {
        let harness = try Harness()
        #expect(!harness.pipeline.attach(sampleRate: 0, channelCount: 1))
    }
}
