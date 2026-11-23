import Core

internal struct SegmentationRun {
    private static let frameSize = 4_096

    private let id: DictationID
    private let scorer: FrameScorer?
    private let continuation: AsyncStream<Segment>.Continuation
    private var assembler = FrameAssembler(frameSize: Self.frameSize)
    private var policy: SegmentationPolicy
    private var nextIndex = 0

    init(
        id: DictationID,
        configuration: SegmentationConfiguration,
        scorer: FrameScorer?,
        continuation: AsyncStream<Segment>.Continuation,
    ) {
        self.id = id
        self.scorer = scorer
        self.continuation = continuation
        policy = SegmentationPolicy(configuration: configuration)
    }

    mutating func consume(_ chunks: AsyncStream<AudioChunk>) async {
        for await chunk in chunks {
            guard !Task.isCancelled else { return }
            for frame in assembler.append(chunk) {
                await classify(frame)
            }
        }
        guard !Task.isCancelled else { return }
        if let tail = assembler.flush() { await classify(tail) }
        if let last = policy.finish() { emit(last, isFinal: true) }
    }

    private mutating func classify(_ frame: FrameAssembler.Frame) async {
        let probability = await scorer?.probability(frame.samples) ?? 1
        let cuts = policy.append(
            frame: frame.samples,
            startSample: frame.startSample,
            probability: probability,
        )
        for cut in cuts { emit(cut, isFinal: false) }
    }

    private mutating func emit(_ cut: SegmentationPolicy.Cut, isFinal: Bool) {
        continuation.yield(
            Segment(
                dictation: id,
                index: nextIndex,
                startSample: cut.startSample,
                audio: cut.audio,
                isFinal: isFinal,
            )
        )
        nextIndex += 1
    }
}
