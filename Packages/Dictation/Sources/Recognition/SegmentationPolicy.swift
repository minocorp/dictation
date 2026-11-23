internal struct SegmentationPolicy {
    struct Cut: Equatable {
        let startSample: Int
        let audio: [Float]
    }

    private struct OpenSegment {
        var startSample: Int
        var audio: [Float]
        var speechSamples: Int
        var trailingSilence: Int
    }

    private let configuration: SegmentationConfiguration
    private var open: OpenSegment?
    private var lead: [Float] = []
    private var isInSpeech = false

    init(configuration: SegmentationConfiguration = .standard) {
        self.configuration = configuration
    }

    mutating func append(frame: [Float], startSample: Int, probability: Float) -> [Cut] {
        let threshold = isInSpeech ? configuration.silenceThreshold : configuration.speechThreshold
        isInSpeech = probability >= threshold
        guard isInSpeech else { return appendSilence(frame) }
        appendSpeech(frame, startSample: startSample)
        return forcedCuts()
    }

    mutating func finish() -> Cut? {
        defer {
            open = nil
            lead = []
        }
        guard let open else { return nil }
        return closed(open)
    }

    private mutating func appendSpeech(_ frame: [Float], startSample: Int) {
        guard var segment = open else {
            open = OpenSegment(
                startSample: startSample - lead.count,
                audio: lead + frame,
                speechSamples: frame.count,
                trailingSilence: 0,
            )
            lead = []
            return
        }
        segment.audio += frame
        segment.speechSamples += frame.count
        segment.trailingSilence = 0
        open = segment
    }

    private mutating func appendSilence(_ frame: [Float]) -> [Cut] {
        guard var segment = open else {
            lead = Array((lead + frame).suffix(configuration.leadingPad))
            return []
        }
        segment.audio += frame
        segment.trailingSilence += frame.count
        guard segment.trailingSilence >= configuration.silenceToCut else {
            open = segment
            return forcedCuts()
        }
        open = nil
        lead = []
        return closed(segment).map { [$0] } ?? []
    }

    private mutating func forcedCuts() -> [Cut] {
        var cuts: [Cut] = []
        while let segment = open, segment.audio.count >= configuration.maximumSegment {
            let index = quietestIndex(in: segment.audio)
            let head = OpenSegment(
                startSample: segment.startSample,
                audio: Array(segment.audio[..<index]),
                speechSamples: min(segment.speechSamples, index),
                trailingSilence: 0,
            )
            let tail = Array(segment.audio[index...])
            open = OpenSegment(
                startSample: segment.startSample + index,
                audio: tail,
                speechSamples: max(tail.count - segment.trailingSilence, 0),
                trailingSilence: min(segment.trailingSilence, tail.count),
            )
            if let cut = closed(head) { cuts.append(cut) }
        }
        return cuts
    }

    private func closed(_ segment: OpenSegment) -> Cut? {
        guard segment.speechSamples >= configuration.minimumSpeech else { return nil }
        let keptSilence = min(segment.trailingSilence, configuration.trailingPad)
        let end = segment.audio.count - segment.trailingSilence + keptSilence
        return Cut(startSample: segment.startSample, audio: Array(segment.audio[..<end]))
    }

    private func quietestIndex(in audio: [Float]) -> Int {
        let window = min(configuration.cutSearchWindow, audio.count)
        let resolution = max(configuration.cutResolution, 1)
        var bestStart = audio.count - window
        var bestEnergy = Float.infinity
        for start in stride(
            from: audio.count - window,
            through: audio.count - resolution,
            by: resolution,
        ) {
            let energy = audio[start..<start + resolution].reduce(0) { $0 + $1 * $1 }
            if energy <= bestEnergy {
                bestEnergy = energy
                bestStart = start
            }
        }
        return min(max(bestStart + resolution / 2, 1), audio.count - 1)
    }
}
