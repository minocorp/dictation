public import Core
public import Foundation

public final class SileroVoiceActivity: VoiceActivity {
    private let makeScorer: @Sendable () async -> FrameScorer?
    private let configuration: SegmentationConfiguration

    public convenience init(modelDirectory: URL? = nil) {
        let model = SileroModel(modelDirectory: modelDirectory)
        self.init(configuration: .standard) { await model.makeScorer() }
    }

    internal init(
        configuration: SegmentationConfiguration,
        makeScorer: @escaping @Sendable () async -> FrameScorer?,
    ) {
        self.configuration = configuration
        self.makeScorer = makeScorer
    }

    public func warmUp() async {
        _ = await makeScorer()
    }

    public func segments(
        of chunks: AsyncStream<AudioChunk>,
        id: DictationID,
    ) -> AsyncStream<Segment> {
        let stream = AsyncStream.makeStream(of: Segment.self)
        let makeScorer = makeScorer
        let configuration = configuration
        let task = Task {
            var run = SegmentationRun(
                id: id,
                configuration: configuration,
                scorer: await makeScorer(),
                continuation: stream.continuation,
            )
            await run.consume(chunks)
            stream.continuation.finish()
        }
        stream.continuation.onTermination = { _ in task.cancel() }
        return stream.stream
    }
}
