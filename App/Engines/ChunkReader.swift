import AVFoundation
import Core
import Foundation
import Synchronization

internal final class ChunkReader: Sendable {
    private struct Position {
        let file: AVAudioFile
        let buffer: AVAudioPCMBuffer
        var nextSample = 0
    }

    private let position: Mutex<Position>
    private let framesPerChunk: AVAudioFrameCount

    init(url: URL, framesPerChunk: AVAudioFrameCount) throws(SpeechError) {
        do {
            let file = try AVAudioFile(forReading: url)
            guard
                let buffer = AVAudioPCMBuffer(
                    pcmFormat: file.processingFormat,
                    frameCapacity: framesPerChunk,
                )
            else { throw SpeechError.failed(code: 0) }
            position = Mutex(Position(file: file, buffer: buffer))
        } catch let error as SpeechError {
            throw error
        } catch {
            throw .failed(code: (error as NSError).code)
        }
        self.framesPerChunk = framesPerChunk
    }

    func next() -> AudioChunk? {
        position.withLock { position in
            guard position.file.framePosition < position.file.length else { return nil }
            do {
                try position.file.read(into: position.buffer, frameCount: framesPerChunk)
            } catch {
                AppLog.failure("read audio file", error)
                return nil
            }
            guard let channel = position.buffer.floatChannelData?[0],
                position.buffer.frameLength > 0
            else { return nil }
            let samples = Array(
                UnsafeBufferPointer(start: channel, count: Int(position.buffer.frameLength))
            )
            defer { position.nextSample += samples.count }
            return AudioChunk(samples: samples, startSample: position.nextSample)
        }
    }
}
