public import Core
public import Foundation
import Synchronization

public final class FakeSpeechEngine: SpeechEngine {
    public struct TranscribeCall: Hashable, Sendable {
        public let segment: Segment
        public let context: String
        public let languages: [Locale]
    }

    private struct State {
        var prepareResult: Result<Void, SpeechError> = .success(())
        var transcribeResult: Result<String, SpeechError> = .success("")
        var prepareCount = 0
        var unloadCount = 0
        var preheatCount = 0
        var transcribeCalls: [TranscribeCall] = []
    }

    private let state = Mutex(State())

    public var prepareResult: Result<Void, SpeechError> {
        get { state.withLock { $0.prepareResult } }
        set { state.withLock { $0.prepareResult = newValue } }
    }

    public var transcribeResult: Result<String, SpeechError> {
        get { state.withLock { $0.transcribeResult } }
        set { state.withLock { $0.transcribeResult = newValue } }
    }

    public var prepareCount: Int { state.withLock { $0.prepareCount } }
    public var unloadCount: Int { state.withLock { $0.unloadCount } }
    public var preheatCount: Int { state.withLock { $0.preheatCount } }
    public var transcribeCalls: [TranscribeCall] { state.withLock { $0.transcribeCalls } }

    public init() {}

    public func prepare() async throws(SpeechError) {
        let result = state.withLock { state in
            state.prepareCount += 1
            return state.prepareResult
        }
        try result.get()
    }

    public func transcribe(
        _ segment: Segment,
        context: String,
        languages: [Locale],
    ) async throws(SpeechError) -> String {
        let result = state.withLock { state in
            state.transcribeCalls.append(
                TranscribeCall(segment: segment, context: context, languages: languages)
            )
            return state.transcribeResult
        }
        return try result.get()
    }

    public func preheat() async {
        state.withLock { $0.preheatCount += 1 }
    }

    public func unload() async {
        state.withLock { $0.unloadCount += 1 }
    }
}
