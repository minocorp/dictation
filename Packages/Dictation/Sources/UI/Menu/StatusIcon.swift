public import Core

public enum StatusIcon: Hashable, Sendable {
    case idle
    case listening
    case downloading
    case problem

    public var symbolName: String {
        switch self {
        case .idle: "waveform"
        case .listening: "mic.fill"
        case .downloading: "arrow.down.circle"
        case .problem: "exclamationmark.triangle"
        }
    }

    public var accessibilityLabel: String {
        switch self {
        case .idle: UIString.string(UIString.menuStatusItemLabel)
        case .listening: UIString.string(UIString.menuStatusListening)
        case .downloading: UIString.string(UIString.menuStatusDownloading)
        case .problem: UIString.string(UIString.menuStatusProblem)
        }
    }

    public static func resolve(
        hud: HUDState,
        permissions: PermissionStatus,
        isDownloading: Bool,
    ) -> StatusIcon {
        if permissions.microphone == .denied || !permissions.isAccessibilityTrusted {
            return .problem
        }
        switch hud {
        case .problem: return .problem
        case .listening, .handsFree, .editing: return .listening
        case .hidden, .processing, .copied, .canceled, .saved, .noSpeech:
            return isDownloading ? .downloading : .idle
        }
    }
}
