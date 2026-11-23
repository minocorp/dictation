import AVFoundation
public import Core
public import Foundation
import Speech

public actor SpeechAnalyzerEngine: SpeechEngine {
    private static let audioConversionFailure = -1

    private let gate: InferenceGate
    private let languages: @Sendable () -> [Locale]
    private var reservedLocale: Locale?
    private var preparation: Task<Result<Void, SpeechError>, Never>?

    public init(gate: InferenceGate, languages: @escaping @Sendable () -> [Locale]) {
        self.gate = gate
        self.languages = languages
    }

    public func prepare() async throws(SpeechError) {
        if let preparation { return try await preparation.value.get() }
        let task = Task { await installOutcome() }
        preparation = task
        defer { preparation = nil }
        try await task.value.get()
    }

    public func transcribe(
        _ segment: Segment,
        context: String,
        languages: [Locale],
    ) async throws(SpeechError) -> String {
        let locale = try await selectLocale(from: languages)
        let transcriber = SpeechTranscriber(locale: locale, preset: .transcription)
        try await requireInstalledAssets(for: transcriber)
        try await reserve(locale)
        return try await gate.run { @Sendable () async throws(SpeechError) -> String in
            try await Self.recognize(segment, with: transcriber)
        }
    }

    public func unload() async {
        if let reservedLocale {
            await AssetInventory.release(reservedLocale: reservedLocale)
            self.reservedLocale = nil
        }
        await SpeechModels.endRetention()
    }

    private static func recognize(
        _ segment: Segment,
        with transcriber: SpeechTranscriber,
    ) async throws(SpeechError) -> String {
        let analyzer = makeAnalyzer(transcriber)
        guard
            let format = await SpeechAnalyzer.bestAvailableAudioFormat(compatibleWith: [transcriber]
            ),
            let buffer = AnalyzerAudioBuffer.make(samples: segment.audio, format: format)
        else { throw .failed(code: audioConversionFailure) }
        let inputs = AsyncStream.makeStream(of: AnalyzerInput.self)
        inputs.continuation.yield(AnalyzerInput(buffer: buffer))
        inputs.continuation.finish()
        async let transcript = Self.transcript(of: transcriber)
        do {
            try await analyzer.start(inputSequence: inputs.stream)
            try await analyzer.finalizeAndFinishThroughEndOfInput()
            return try await transcript
        } catch {
            await analyzer.cancelAndFinishNow()
            throw Self.failure(error)
        }
    }

    private func selectLocale(from languages: [Locale]) async throws(SpeechError) -> Locale {
        let selected = await SpeechLocaleSelection.firstSupported(in: languages) {
            await SpeechTranscriber.supportedLocale(equivalentTo: $0)
        }
        guard let selected else { throw .unsupportedLanguage }
        return selected
    }

    private func installOutcome() async -> Result<Void, SpeechError> {
        do throws(SpeechError) {
            try await install()
            return .success(())
        } catch {
            return .failure(error)
        }
    }

    private func install() async throws(SpeechError) {
        let locale = try await selectLocale(from: languages())
        guard SpeechTranscriber.isAvailable else { throw .modelUnavailable }
        let transcriber = SpeechTranscriber(locale: locale, preset: .transcription)
        try await downloadAssetsIfNeeded(for: transcriber)
        try await reserve(locale)
        let analyzer = Self.makeAnalyzer(transcriber)
        do {
            try await analyzer.prepareToAnalyze(in: nil)
        } catch {
            await analyzer.cancelAndFinishNow()
            throw Self.failure(error)
        }
        await analyzer.cancelAndFinishNow()
    }

    private func requireInstalledAssets(
        for transcriber: SpeechTranscriber
    ) async throws(SpeechError) {
        switch await AssetInventory.status(forModules: [transcriber]) {
        case .installed: return
        case .supported, .downloading: throw .modelUnavailable
        case .unsupported: throw .unsupportedLanguage
        @unknown default: throw .modelUnavailable
        }
    }

    private func downloadAssetsIfNeeded(
        for transcriber: SpeechTranscriber
    ) async throws(SpeechError) {
        switch await AssetInventory.status(forModules: [transcriber]) {
        case .installed:
            break
        case .supported, .downloading:
            do {
                try await AssetInventory.assetInstallationRequest(supporting: [transcriber])?
                    .downloadAndInstall()
            } catch {
                throw Self.failure(error)
            }
        case .unsupported:
            throw .unsupportedLanguage
        @unknown default:
            throw .modelUnavailable
        }
    }

    private func reserve(_ locale: Locale) async throws(SpeechError) {
        guard reservedLocale != locale else { return }
        if let previous = reservedLocale {
            await AssetInventory.release(reservedLocale: previous)
            reservedLocale = nil
        }
        do {
            try await AssetInventory.reserve(locale: locale)
        } catch {
            throw Self.failure(error)
        }
        reservedLocale = locale
    }

    private static func makeAnalyzer(_ transcriber: SpeechTranscriber) -> SpeechAnalyzer {
        SpeechAnalyzer(
            modules: [transcriber],
            options: SpeechAnalyzer.Options(
                priority: .userInitiated,
                modelRetention: .processLifetime,
            ),
        )
    }

    private static func transcript(of transcriber: SpeechTranscriber) async throws -> String {
        var text = ""
        for try await result in transcriber.results {
            text += String(result.text.characters)
        }
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func failure(_ error: any Error) -> SpeechError {
        Task.isCancelled ? .cancelled : .failed(code: (error as NSError).code)
    }
}
