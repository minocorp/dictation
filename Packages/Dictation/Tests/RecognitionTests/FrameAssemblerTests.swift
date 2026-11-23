import Core
@testable import Recognition
import Testing

internal struct FrameAssemblerTests {
    @Test
    func chunksOfAnySizeBecomeContiguousFixedFrames() {
        var assembler = FrameAssembler(frameSize: 100)
        let samples = (0..<1_000).map { Float($0) }
        var frames: [FrameAssembler.Frame] = []
        var start = 0
        for size in [30, 170, 1, 299, 250, 250] {
            frames += assembler.append(
                AudioChunk(samples: Array(samples[start..<start + size]), startSample: start)
            )
            start += size
        }
        #expect(frames.count == 10)
        #expect(frames.map(\.startSample) == Array(stride(from: 0, to: 1_000, by: 100)))
        #expect(frames.flatMap(\.samples) == samples)
        #expect(assembler.flush() == nil)
    }

    @Test
    func flushReturnsTheShortTail() {
        var assembler = FrameAssembler(frameSize: 100)
        _ = assembler.append(
            AudioChunk(samples: [Float](repeating: 1, count: 130), startSample: 500)
        )
        let tail = assembler.flush()
        #expect(
            tail
                == FrameAssembler.Frame(
                    startSample: 600,
                    samples: [Float](repeating: 1, count: 30),
                )
        )
        #expect(assembler.flush() == nil)
    }

    @Test
    func gapInTheTimelineStartsANewFrame() {
        var assembler = FrameAssembler(frameSize: 100)
        _ = assembler.append(
            AudioChunk(samples: [Float](repeating: 1, count: 40), startSample: 0)
        )
        let frames = assembler.append(
            AudioChunk(samples: [Float](repeating: 2, count: 100), startSample: 1_000)
        )
        #expect(frames.map(\.startSample) == [0, 1_000])
        #expect(frames.map(\.samples.count) == [40, 100])
    }
}
