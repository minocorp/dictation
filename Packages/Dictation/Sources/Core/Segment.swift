public struct Segment: Hashable, Sendable {
    public let dictation: DictationID
    public let index: Int
    public let startSample: Int
    public let audio: [Float]
    public let isFinal: Bool

    public init(
        dictation: DictationID,
        index: Int,
        startSample: Int,
        audio: [Float],
        isFinal: Bool,
    ) {
        self.dictation = dictation
        self.index = index
        self.startSample = startSample
        self.audio = audio
        self.isFinal = isFinal
    }
}
