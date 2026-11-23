import Core
import Foundation

internal enum Request: Equatable, Sendable {
    case modelReady(ModelStage, pending: [HistoryItem])
    case retry(HistoryItem)
    case launched(orphans: [URL], at: Date)
}
