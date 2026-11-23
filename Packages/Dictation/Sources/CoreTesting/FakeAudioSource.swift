public import Core
public import Foundation
import Synchronization

public final class FakeAudioSource: AudioSource {
    public struct StartCall: Hashable, Sendable {
        public let device: InputDevice
        public let id: DictationID
    }

    private struct State {
        var startResult: Result<Void, CaptureError> = .success(())
        var stopURL: URL?
        var startCalls: [StartCall] = []
        var stopCount = 0
        var chunkContinuation: AsyncStream<AudioChunk>.Continuation?
        var failureContinuation: AsyncStream<CaptureError>.Continuation?
        var discarded: [URL] = []
    }

    public let levels: AsyncStream<Float>

    private let levelContinuation: AsyncStream<Float>.Continuation
    private let state = Mutex(State())

    public var startResult: Result<Void, CaptureError> {
        get { state.withLock { $0.startResult } }
        set { state.withLock { $0.startResult = newValue } }
    }

    public var stopURL: URL? {
        get { state.withLock { $0.stopURL } }
        set { state.withLock { $0.stopURL = newValue } }
    }

    public var startCalls: [StartCall] { state.withLock { $0.startCalls } }
    public var stopCount: Int { state.withLock { $0.stopCount } }
    public var discarded: [URL] { state.withLock { $0.discarded } }

    public init() {
        let stream = AsyncStream.makeStream(of: Float.self, bufferingPolicy: .bufferingNewest(1))
        levels = stream.stream
        levelContinuation = stream.continuation
    }

    public func emit(_ chunk: AudioChunk) {
        let continuation = state.withLock { $0.chunkContinuation }
        continuation?.yield(chunk)
    }

    public func emitFailure(_ error: CaptureError) {
        let continuation = state.withLock { $0.failureContinuation }
        continuation?.yield(error)
    }

    public func emitLevel(_ level: Float) {
        levelContinuation.yield(level)
    }

    public func start(
        device: InputDevice,
        id: DictationID,
    ) async throws(CaptureError) -> AudioCapture {
        let chunks = AsyncStream.makeStream(of: AudioChunk.self)
        let failures = AsyncStream.makeStream(of: CaptureError.self)
        let result = state.withLock { state in
            state.startCalls.append(StartCall(device: device, id: id))
            if case .success = state.startResult {
                state.chunkContinuation = chunks.continuation
                state.failureContinuation = failures.continuation
            }
            return state.startResult
        }
        try result.get()
        return AudioCapture(chunks: chunks.stream, failures: failures.stream)
    }

    public func stop() async -> URL? {
        let (chunks, failures, url) = state.withLock { state in
            state.stopCount += 1
            defer {
                state.chunkContinuation = nil
                state.failureContinuation = nil
            }
            return (state.chunkContinuation, state.failureContinuation, state.stopURL)
        }
        chunks?.finish()
        failures?.finish()
        return url
    }

    public func discard(audioAt url: URL) async {
        state.withLock { $0.discarded.append(url) }
    }
}
