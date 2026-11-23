import Core
import Foundation

extension HandsFreeSilenceLimit {
    var label: LocalizedStringResource {
        switch self {
        case .seconds30: UIString.settingsSilence30Seconds
        case .minutes2: UIString.settingsSilence2Minutes
        case .minutes10: UIString.settingsSilence10Minutes
        case .never: UIString.settingsSilenceNever
        }
    }
}
