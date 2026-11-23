import Core
import Foundation
@testable import Recognition
import Testing

internal struct SpeechAnalyzerEngineTests {
    private func engine(languages: [Locale]) -> SpeechAnalyzerEngine {
        SpeechAnalyzerEngine(gate: InferenceGate(), languages: { languages })
    }

    private func segment(_ audio: [Float]) -> Segment {
        Segment(dictation: DictationID(), index: 0, startSample: 0, audio: audio, isFinal: true)
    }

    @Test
    func unsupportedLanguageIsReportedBeforeAnyWork() async {
        let engine = engine(languages: [])
        await #expect(throws: SpeechError.unsupportedLanguage) {
            try await engine.prepare()
        }
        await #expect(throws: SpeechError.unsupportedLanguage) {
            try await engine.transcribe(
                segment(SpeechFixture.silence(seconds: 0.5)),
                context: "",
                languages: [Locale(identifier: "tlh")],
            )
        }
    }

    @Test(.enabled(if: SpeechFixture.isSayAvailable))
    func spokenEnglishIsTranscribed() async throws {
        let engine = engine(languages: [Locale(identifier: "en-US")])
        do {
            try await engine.prepare()
        } catch {
            try Test.cancel("SpeechAnalyzer assets are not available: \(error)")
        }
        let audio = try SpeechFixture.spoken("Hello world, this is a dictation test.")
        let text = try await engine.transcribe(
            segment(audio),
            context: "",
            languages: [Locale(identifier: "en-US")],
        )
        #expect(text.lowercased().contains("dictation"))
        await engine.unload()
    }
}
