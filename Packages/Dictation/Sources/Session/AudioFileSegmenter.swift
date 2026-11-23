public import Core
public import Foundation

public protocol AudioFileSegmenter: Sendable {
    func segments(of audioURL: URL, id: DictationID) throws(SpeechError) -> AsyncStream<Segment>
}
