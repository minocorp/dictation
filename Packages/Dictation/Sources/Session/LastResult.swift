public import Core

public struct LastResult: Equatable, Sendable {
    public let item: HistoryItem
    public let target: FocusSnapshot?
}
