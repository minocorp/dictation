import Core
import Foundation

extension HistoryItem.Status {
    var label: LocalizedStringResource? {
        switch self {
        case .inserted: nil
        case .copied: UIString.historyStatusCopied
        case .canceled: UIString.historyStatusCanceled
        case .pending: UIString.historyStatusPending
        case .recovered: UIString.historyStatusRecovered
        case .failed: UIString.historyStatusFailed
        case .refused: UIString.historyStatusRefused
        }
    }
}
