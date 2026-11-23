import Core
import Foundation

extension Permission {
    var settingsURLs: [URL] {
        let anchor =
            switch self {
            case .microphone: "Privacy_Microphone"
            case .accessibility: "Privacy_Accessibility"
            }
        return [
            "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?\(anchor)",
            "x-apple.systempreferences:com.apple.preference.security?\(anchor)",
        ]
        .compactMap { URL(string: $0) }
    }
}
