import Core
import Foundation
import FoundationModels

internal enum FoundationModelsErrorMap {
    static func cleanupError(from error: any Error) -> CleanupError {
        if Task.isCancelled { return .cancelled }
        if let generation = error as? LanguageModelSession.GenerationError {
            return map(generation)
        }
        if #available(macOS 27.0, *), let modelError = error as? LanguageModelError {
            return map(modelError)
        }
        return .failed(code: (error as NSError).code)
    }

    private static func map(_ error: LanguageModelSession.GenerationError) -> CleanupError {
        switch error {
        case .guardrailViolation, .refusal, .unsupportedLanguageOrLocale,
            .exceededContextWindowSize,
            .decodingFailure, .unsupportedGuide:
            .rejected
        case .assetsUnavailable:
            .modelUnavailable
        case .rateLimited, .concurrentRequests:
            .failed(code: (error as NSError).code)
        @unknown default:
            .failed(code: (error as NSError).code)
        }
    }

    @available(macOS 27.0, *)
    private static func map(_ error: LanguageModelError) -> CleanupError {
        switch error {
        case .guardrailViolation, .refusal, .unsupportedLanguageOrLocale, .contextSizeExceeded,
            .unsupportedCapability, .unsupportedTranscriptContent, .unsupportedGenerationGuide:
            .rejected
        case .timeout:
            .timedOut
        case .rateLimited:
            .failed(code: (error as NSError).code)
        @unknown default:
            .failed(code: (error as NSError).code)
        }
    }
}
