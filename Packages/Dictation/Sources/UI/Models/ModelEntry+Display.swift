import Core
import Foundation

extension ModelEntry {
    var localizedName: String {
        if id == Self.appleSpeechAnalyzer.id {
            return UIString.string(UIString.modelsBuiltInSpeechName)
        }
        if id == Self.appleFoundationModels.id {
            return UIString.string(UIString.modelsBuiltInCleanupName)
        }
        return displayName
    }
}

extension ModelError {
    var message: LocalizedStringResource {
        switch self {
        case .cancelled, .unknownModel: UIString.modelsErrorUnknown
        case .insufficientDiskSpace: UIString.modelsErrorDiskSpace
        case .networkFailed: UIString.modelsErrorNetwork
        case .sizeMismatch, .hashMismatch: UIString.modelsErrorVerification
        case .fileFailed: UIString.modelsErrorFile
        case .loadFailed: UIString.modelsErrorLoad
        }
    }
}
