#if DEBUG
import Core
import Foundation
import Session

@MainActor
internal struct PipelineBenchmark {
    let core: AppCore
    let request: PipelineBenchmarkRequest

    func run() async {
        await core.voice.warmUp()
        await core.engines.resolver.warmUp()
        for run in 1...request.runs {
            for url in request.audioURLs {
                try? await Task.sleep(for: request.gap)
                await preheat()
                await once(run, audioURL: url)
            }
        }
    }

    private func once(_ run: Int, audioURL: URL) async {
        let id = DictationID()
        TimingLog.keyDown(id)
        TimingLog.keyUp(id)
        let clock = ContinuousClock()
        let start = clock.now
        let segmenter = CAFAudioFileSegmenter(voice: core.voice)
        var segments: [Segment] = []
        do {
            for await segment in try segmenter.segments(of: audioURL, id: id) {
                segments.append(segment)
            }
        } catch {
            AppLog.failure("benchmark audio", error)
            return
        }
        let segmented = clock.now
        var texts: [String] = []
        var finals: [String] = []
        var speechTime = Duration.zero
        var cleanupTime = Duration.zero
        for segment in segments {
            let speechStart = clock.now
            let raw = await transcribe(segment)
            speechTime += speechStart.duration(to: clock.now)
            let cleanupStart = clock.now
            let cleaned = await clean(raw, isFinal: segment.isFinal)
            cleanupTime += cleanupStart.duration(to: clock.now)
            texts.append(raw)
            finals.append(cleaned)
        }
        let audioSeconds =
            Double(segments.reduce(0) { $0 + $1.audio.count }) / Double(AudioChunk.sampleRate)
        let line =
            "bench run=\(run) file=\(audioURL.lastPathComponent.prefix(8)) audio-s=\(String(format: "%.2f", audioSeconds)) segments=\(segments.count) vad-ms=\(start.duration(to: segmented).milliseconds) asr-ms=\(speechTime.milliseconds) cleanup-ms=\(cleanupTime.milliseconds) total-ms=\(start.duration(to: clock.now).milliseconds) raw=\(texts.joined(separator: " | ")) final=\(finals.joined(separator: " | "))"
        TimingLog.mark("bench-result", line, for: id)
        FileHandle.standardOutput.write(Data((line + "\n").utf8))
    }

    private func preheat() async {
        guard request.preheat > .zero else { return }
        let speech = await core.engines.resolver.speech()
        let cleanup = await core.engines.resolver.cleanup()
        let warming = Task {
            await speech.preheat()
            await cleanup.preheat()
        }
        try? await Task.sleep(for: request.preheat)
        await warming.value
    }

    private func transcribe(_ segment: Segment) async -> String {
        let preferences = core.preferences.read()
        let words = await Self.dictionary(core.stores.words)
        let context = SessionRunner.recognitionContext(from: words)
        let provider = core.engines.resolver
        let task = Task {
            let engine = await provider.speech()
            do throws(SpeechError) {
                return try await engine.transcribe(
                    segment,
                    context: context,
                    languages: preferences.languages,
                )
            } catch {
                return ""
            }
        }
        return await task.value
    }

    private func clean(_ text: String, isFinal: Bool) async -> String {
        let words = await Self.dictionary(core.stores.words)
        let pipeline = EngineCleanupPipeline(
            resolver: core.engines.resolver,
            preferences: core.preferences,
            budget: .recommended(for: RAMTier(ramGB: MachineMemory.gigabytes)),
        )
        let input = CleanInput(
            text: text,
            contextBefore: request.contextBefore,
            isFinalSegment: isFinal,
        )
        let task = Task {
            do throws(CleanupError) {
                return try await pipeline.clean(input, dictionary: words)
            } catch {
                return text
            }
        }
        return await task.value
    }

    private static func dictionary(_ store: any WordStore) async -> [Word] {
        do throws(StoreError) {
            return try await store.all()
        } catch {
            return []
        }
    }
}
#endif
