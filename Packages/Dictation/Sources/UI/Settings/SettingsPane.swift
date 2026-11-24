import Foundation

public enum SettingsPane: Hashable, Sendable, CaseIterable {
    case general
    case dictionary
    case models
    case history
    case about

    var title: LocalizedStringResource {
        switch self {
        case .general: UIString.settingsPaneGeneral
        case .dictionary: UIString.settingsPaneDictionary
        case .models: UIString.settingsPaneModels
        case .history: UIString.settingsPaneHistory
        case .about: UIString.settingsPaneAbout
        }
    }

    var symbol: String {
        switch self {
        case .general: "gearshape"
        case .dictionary: "text.book.closed"
        case .models: "cube"
        case .history: "clock"
        case .about: "info.circle"
        }
    }
}
