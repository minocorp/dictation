import Core
import Foundation

extension HistoryRetention {
    var label: LocalizedStringResource {
        switch self {
        case .off: UIString.historyRetentionOff
        case .oneDay: UIString.historyRetentionOneDay
        case .thirtyDays: UIString.historyRetentionThirtyDays
        }
    }
}
