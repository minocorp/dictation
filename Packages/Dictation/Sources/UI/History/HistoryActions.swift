public import Core
import Foundation

public struct HistoryActions {
    let observe: @MainActor (String) -> AsyncStream<[HistoryItem]>
    let copy: @MainActor (String) -> Void
    let retry: @MainActor (DictationID) async -> Void

    public init(
        observe: @escaping @MainActor (String) -> AsyncStream<[HistoryItem]>,
        copy: @escaping @MainActor (String) -> Void,
        retry: @escaping @MainActor (DictationID) async -> Void,
    ) {
        self.observe = observe
        self.copy = copy
        self.retry = retry
    }
}
