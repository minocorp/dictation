internal struct SegmentationConfiguration: Sendable {
    static let sampleRate = 16_000

    let silenceToCut: Int
    let minimumSpeech: Int
    let maximumSegment: Int
    let cutSearchWindow: Int
    let cutResolution: Int
    let leadingPad: Int
    let trailingPad: Int
    let speechThreshold: Float
    let silenceThreshold: Float

    static let standard = SegmentationConfiguration(
        silenceToCut: samples(milliseconds: 600),
        minimumSpeech: samples(milliseconds: 200),
        maximumSegment: samples(milliseconds: 10_000),
        cutSearchWindow: samples(milliseconds: 2_000),
        cutResolution: samples(milliseconds: 20),
        leadingPad: samples(milliseconds: 100),
        trailingPad: samples(milliseconds: 100),
        speechThreshold: 0.5,
        silenceThreshold: 0.35,
    )

    static func samples(milliseconds: Int) -> Int {
        sampleRate * milliseconds / 1_000
    }
}
