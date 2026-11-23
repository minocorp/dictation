import AVFoundation
import Core
import Foundation
import Session

internal struct CAFAudioFileSegmenter: AudioFileSegmenter {
    private static let framesPerChunk: AVAudioFrameCount = 16_000

    let voice: any VoiceActivity

    func segments(of audioURL: URL, id: DictationID) throws(SpeechError) -> AsyncStream<Segment> {
        voice.segments(of: try Self.chunks(of: audioURL), id: id)
    }

    static func chunks(of audioURL: URL) throws(SpeechError) -> AsyncStream<AudioChunk> {
        let reader = try ChunkReader(url: audioURL, framesPerChunk: framesPerChunk)
        return AsyncStream(unfolding: { reader.next() })
    }
}
