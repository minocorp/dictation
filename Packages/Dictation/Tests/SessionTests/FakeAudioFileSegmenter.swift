import Core
import Foundation
@testable import Session
import Synchronization

internal final class FakeAudioFileSegmenter: AudioFileSegmenter {
    private struct State {
        var segmentCount = 1
        var failure: SpeechError?
        var requests: [URL] = []
    }

    private let state = Mutex(State())

    var segmentCount: Int {
        get { state.withLock { $0.segmentCount } }
        set { state.withLock { $0.segmentCount = newValue } }
    }

    var failure: SpeechError? {
        get { state.withLock { $0.failure } }
        set { state.withLock { $0.failure = newValue } }
    }

    var requests: [URL] { state.withLock { $0.requests } }

    func segments(of audioURL: URL, id: DictationID) throws(SpeechError) -> AsyncStream<Segment> {
        let (count, failure) = state.withLock { state in
            state.requests.append(audioURL)
            return (state.segmentCount, state.failure)
        }
        if let failure { throw failure }
        return AsyncStream { continuation in
            for index in 0..<count {
                continuation.yield(Fixture.segment(index, id))
            }
            continuation.finish()
        }
    }
}
