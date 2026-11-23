internal import Core
internal import Foundation
internal import QwenASR

internal struct ASRCommand {
    struct Options {
        let languages: [Locale]
        let context: String
        let trimMilliseconds: Int
    }

    let arguments: Arguments
    let root: URL

    func run() async throws(EvalError) -> String {
        let model = try arguments.required("model")
        let setName = try arguments.required("set")
        guard let set = AudioSet(rawValue: setName) else {
            throw .usage("unknown set \(setName); one of \(AudioSet.allCases.map(\.rawValue))")
        }
        let limit = try arguments.integer("limit", default: 20)
        let loader = AudioSetLoader(root: root, client: DatasetServerClient(session: .shared))
        let clips = try await loader.clips(of: set, limit: limit)
        let engine = QwenASREngine(directory: URL(fileURLWithPath: model), gate: InferenceGate())
        do {
            try await engine.prepare()
        } catch {
            throw .engine("cannot load \(model): \(error)")
        }
        let languages = try languages(for: set)
        let context = arguments.value(for: "context") ?? ""
        let trim = try arguments.integer("trim-ms", default: 0)
        let results = try await transcribe(
            clips,
            with: engine,
            options: Options(languages: languages, context: context, trimMilliseconds: trim),
        )
        await engine.unload()
        return ASRReport(set: set, model: model, results: results).markdown()
    }

    private func languages(for set: AudioSet) throws(EvalError) -> [Locale] {
        guard let value = arguments.value(for: "language") else { return set.languages }
        if value == "auto" { return [] }
        let codes = value.split(separator: ",").map(String.init)
        guard !codes.isEmpty else { throw .usage("--language must be auto or codes like ko,en") }
        return codes.map { Locale(identifier: $0) }
    }

    private func trimmed(_ samples: [Float], options: Options) -> [Float] {
        guard options.trimMilliseconds > 0 else { return samples }
        return Array(samples.prefix(options.trimMilliseconds * AudioChunk.sampleRate / 1000))
    }

    private func transcribe(
        _ clips: [AudioClip],
        with engine: QwenASREngine,
        options: Options,
    ) async throws(EvalError) -> [ASRClipResult] {
        var results: [ASRClipResult] = []
        for (index, clip) in clips.enumerated() {
            let samples = try trimmed(AudioDecoder.samples(from: clip.file), options: options)
            let segment = Segment(
                dictation: DictationID(),
                index: 0,
                startSample: 0,
                audio: samples,
                isFinal: true,
            )
            if index == 0 {
                _ = try? await engine.transcribe(
                    segment,
                    context: options.context,
                    languages: options.languages,
                )
            }
            let clock = ContinuousClock()
            let start = clock.now
            let text: String
            do {
                text = try await engine.transcribe(
                    segment,
                    context: options.context,
                    languages: options.languages,
                )
            } catch {
                throw .engine("\(clip.id): \(error)")
            }
            results.append(
                ASRClipResult(
                    clip: clip,
                    hypothesis: text,
                    audioSeconds: Double(samples.count) / Double(AudioChunk.sampleRate),
                    latency: start.duration(to: clock.now),
                )
            )
            FileHandle.standardError.write(Data("\(clip.id) \(text)\n".utf8))
        }
        return results
    }
}
