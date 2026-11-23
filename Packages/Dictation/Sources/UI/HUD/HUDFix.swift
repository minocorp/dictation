public import Core
import Foundation

public enum HUDFix: Hashable, Sendable {
    case openPermissionSettings(Permission)
    case openModels
}

extension Problem {
    public var fix: HUDFix? {
        switch self {
        case .microphoneUnavailable, .microphoneDenied: .openPermissionSettings(.microphone)
        case .accessibilityOff: .openPermissionSettings(.accessibility)
        case .couldNotTranscribe: .openModels
        case .passwordField, .couldNotEdit, .selectionTooLong, .couldNotSave: nil
        }
    }

    var message: LocalizedStringResource {
        switch self {
        case .microphoneUnavailable: UIString.hudProblemMicrophoneUnavailable
        case .microphoneDenied: UIString.hudProblemMicrophoneDenied
        case .accessibilityOff: UIString.hudProblemAccessibilityOff
        case .passwordField: UIString.hudProblemPasswordField
        case .couldNotEdit: UIString.hudProblemCouldNotEdit
        case .selectionTooLong: UIString.hudProblemSelectionTooLong
        case .couldNotTranscribe: UIString.hudProblemCouldNotTranscribe
        case .couldNotSave: UIString.hudProblemCouldNotSave
        }
    }
}
