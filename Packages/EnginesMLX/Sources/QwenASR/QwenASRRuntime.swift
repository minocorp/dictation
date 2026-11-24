import Core
import Foundation
import MLX
import MLXAudioSTT
import MLXMemory

internal actor QwenASRRuntime {
    private static let warmUpSamples = 16_000

    private let memory = IdleCacheTrimmer()
    private var model: Qwen3ASRModel?

    func load(from directory: URL) async throws(SpeechError) {
        guard model == nil else { return }
        if Task.isCancelled { throw .cancelled }
        memory.limitCache()
        do {
            model = try await Qwen3ASRModel.fromModelDirectory(directory)
        } catch {
            throw Task.isCancelled ? .cancelled : .modelUnavailable
        }
    }

    func warmUp() {
        guard let model else { return }
        memory.begin()
        defer { memory.end() }
        _ = model.generate(
            audio: MLXArray([Float](repeating: 0, count: Self.warmUpSamples)),
            context: "",
            language: nil,
        )
    }

    func transcribe(_ request: QwenASRRequest) throws(SpeechError) -> QwenASRResult {
        guard let model else { throw .modelUnavailable }
        if Task.isCancelled { throw .cancelled }
        memory.begin()
        defer { memory.end() }
        let clock = ContinuousClock()
        let start = clock.now
        let output = model.generate(
            audio: MLXArray(request.audio),
            context: request.context,
            language: request.language,
        )
        TimingLog.mark(
            "asr-generate",
            "ms=\(start.duration(to: clock.now).milliseconds) samples=\(request.audio.count) forced-language=\(request.language ?? "-")",
        )
        return QwenASRResult(
            text: output.text.trimmingCharacters(in: .whitespacesAndNewlines),
            detectedLanguage: output.language,
            promptTokens: output.promptTokens,
            generatedTokens: output.generationTokens,
        )
    }

    func unload() {
        memory.begin()
        model = nil
        Memory.clearCache()
    }
}
