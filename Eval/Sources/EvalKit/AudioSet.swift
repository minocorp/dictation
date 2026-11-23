internal import Foundation

public enum AudioSet: String, CaseIterable, Sendable {
    case fleursKorean = "fleurs-ko"
    case fleursEnglish = "fleurs-en"
    case zerothKorean = "zeroth-ko"
    case hike

    var dataset: String {
        switch self {
        case .fleursKorean, .fleursEnglish: "google/fleurs"
        case .zerothKorean: "kresnik/zeroth_korean"
        case .hike: "thetaone-ai/HiKE"
        }
    }

    var configuration: String {
        switch self {
        case .fleursKorean: "ko_kr"
        case .fleursEnglish: "en_us"
        case .zerothKorean, .hike: "default"
        }
    }

    var referenceField: String {
        switch self {
        case .fleursKorean, .fleursEnglish: "raw_transcription"
        case .zerothKorean, .hike: "text"
        }
    }

    var languages: [Locale] {
        switch self {
        case .fleursKorean, .zerothKorean: [Locale(identifier: "ko")]
        case .fleursEnglish: [Locale(identifier: "en")]
        case .hike: [Locale(identifier: "ko"), Locale(identifier: "en")]
        }
    }

    var normalizationLanguage: TextNormalizer.Language {
        switch self {
        case .fleursEnglish: .english
        case .fleursKorean, .zerothKorean, .hike: .korean
        }
    }

    var errorUnit: ErrorRate.Unit {
        switch self {
        case .fleursEnglish: .word
        case .fleursKorean, .zerothKorean, .hike: .character
        }
    }
}
