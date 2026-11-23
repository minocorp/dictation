import Core
import Foundation
@testable import QwenASR
import Testing

private let modelDirectory = ProcessInfo.processInfo.environment["QWEN_ASR_MODEL_DIR"]

@Suite(.enabled(if: modelDirectory != nil))
internal struct QwenASRIntegrationTests {
    @Test
    func transcribesSilenceWithoutFailingAndUnloads() async throws {
        let directory = try #require(modelDirectory)
        let engine = QwenASREngine(
            directory: URL(fileURLWithPath: directory),
            gate: InferenceGate(),
        )
        try await engine.prepare()
        let segment = Segment(
            dictation: DictationID(),
            index: 0,
            startSample: 0,
            audio: [Float](repeating: 0, count: AudioChunk.sampleRate),
            isFinal: true,
        )
        _ = try await engine.transcribe(
            segment,
            context: "",
            languages: [Locale(identifier: "ko")],
        )
        await engine.unload()
    }
}
