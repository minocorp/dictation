public import Core
import Foundation

extension SessionRunner {
    private static let recognitionContextWordLimit = 20

    func preheatEngines(for id: DictationID) {
        let preheat = engines.preheat
        spawn(id) {
            TimingLog.mark("preheat-start", for: id)
            await preheat()
            TimingLog.mark("preheat-end", for: id)
        }
    }

    func transcribe(_ segment: Segment, languages: [Locale]) {
        let provider = engines.speech
        let words = engines.words
        let id = segment.dictation
        spawn(id) { [weak self] in
            TimingLog.mark("asr-start", "index=\(segment.index)", for: id)
            let dictionary = await Result.awaiting { () async throws(StoreError) -> [Word] in
                try await words.all()
            }
            let context = Self.recognitionContext(from: dictionary.value ?? [])
            let engine = await provider()
            TimingLog.mark("asr-engine-ready", "index=\(segment.index)", for: id)
            let result = await Result.awaiting { () async throws(SpeechError) -> String in
                try await engine.transcribe(segment, context: context, languages: languages)
            }
            TimingLog.mark(
                "asr-end",
                "index=\(segment.index) ok=\(result.value != nil) characters=\(result.value?.count ?? 0)",
                for: id,
            )
            self?.send(.result(id, .transcribed(index: segment.index, result: result)))
        }
    }

    public static func recognitionContext(from words: [Word]) -> String {
        words.prefix(recognitionContextWordLimit).map(\.text).joined(separator: ", ")
    }

    func clean(_ id: DictationID, index: Int, input: CleanInput) {
        let words = engines.words
        let pipeline = engines.cleanup
        spawn(id) { [weak self] in
            TimingLog.mark(
                "cleanup-start",
                "index=\(index) final=\(input.isFinalSegment)",
                for: id,
            )
            let dictionary = await Result.awaiting { () async throws(StoreError) -> [Word] in
                try await words.all()
            }
            let result = await Result.awaiting { () async throws(CleanupError) -> String in
                try await pipeline.clean(input, dictionary: dictionary.value ?? [])
            }
            TimingLog.mark("cleanup-end", "index=\(index) ok=\(result.value != nil)", for: id)
            self?.send(.result(id, .cleaned(index: index, result: result)))
        }
    }

    func edit(_ id: DictationID, selection: String, instruction: String) {
        let pipeline = engines.cleanup
        spawn(id) { [weak self] in
            let result = await Result.awaiting { () async throws(CleanupError) -> String in
                try await pipeline.edit(selection: selection, instruction: instruction)
            }
            self?.send(.result(id, .edited(result)))
        }
    }
}
