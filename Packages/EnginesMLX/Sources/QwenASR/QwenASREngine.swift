public import Core
public import Foundation
public import ModelCatalog

public final class QwenASREngine: SpeechEngine {
    public static let kind = "qwen3-asr"

    private let directory: URL
    private let gate: InferenceGate
    private let runtime = QwenASRRuntime()

    public init(directory: URL, gate: InferenceGate) {
        self.directory = directory
        self.gate = gate
    }

    public static func register(in registry: EngineRegistry, gate: InferenceGate) {
        registry.registerSpeech(kind: kind) { _, directory in
            QwenASREngine(directory: directory, gate: gate)
        }
    }

    public func prepare() async throws(SpeechError) {
        try await gate.run { () async throws(SpeechError) in
            try await runtime.load(from: directory)
            await runtime.warmUp()
        }
    }

    public func transcribe(
        _ segment: Segment,
        context: String,
        languages: [Locale],
    ) async throws(SpeechError) -> String {
        guard !segment.audio.isEmpty else { return "" }
        let context = RecognitionContext.trimmed(context)
        let request = QwenASRRequest(
            audio: segment.audio,
            context: context,
            language: SpokenLanguage.name(for: languages),
        )
        let requested = ContinuousClock.now
        return try await UserInitiated.run { [self] () async throws(SpeechError) -> String in
            try await gate.run { () async throws(SpeechError) -> String in
                TimingLog.mark(
                    "asr-gate-acquired",
                    "wait-ms=\(requested.duration(to: .now).milliseconds) \(TimingLog.executionContext)",
                )
                try await runtime.load(from: directory)
                var result = try await runtime.transcribe(request)
                var redecoded = false
                if !SpokenLanguage.isAllowed(
                    detected: result.detectedLanguage,
                    text: result.text,
                    languages: languages,
                ) {
                    redecoded = true
                    let pinned = QwenASRRequest(
                        audio: request.audio,
                        context: request.context,
                        language: SpokenLanguage.primaryName(for: languages),
                    )
                    result = try await runtime.transcribe(pinned)
                }
                TimingLog.mark(
                    "asr-decoded",
                    "redecoded=\(redecoded) language=\(result.detectedLanguage ?? "-") prompt-tokens=\(result.promptTokens) generated-tokens=\(result.generatedTokens)",
                )
                return result.text
            }
        }
    }

    public func preheat() async {
        do throws(SpeechError) {
            try await UserInitiated.run { [self] () async throws(SpeechError) in
                try await gate.run { () async throws(SpeechError) in
                    TimingLog.mark("asr-preheat-start", TimingLog.executionContext)
                    await runtime.warmUp()
                    TimingLog.mark("asr-preheat-end")
                }
            }
        } catch {
            TimingLog.mark("asr-preheat-end", "cancelled")
        }
    }

    public func unload() async {
        await runtime.unload()
    }
}
