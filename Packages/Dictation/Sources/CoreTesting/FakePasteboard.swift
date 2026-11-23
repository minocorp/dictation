package import Foundation
package import Pasteboard
import Synchronization

package final class FakePasteboard: PasteboardAccess {
    private struct State {
        var items: [PasteboardItem]
        var changeCount = 0
    }

    private let state: Mutex<State>

    package var changeCount: Int { state.withLock { $0.changeCount } }
    package var currentItems: [PasteboardItem] { state.withLock { $0.items } }

    package var plainText: String? {
        data(forType: PasteboardType.plainText).flatMap { String(data: $0, encoding: .utf8) }
    }

    package init(items: [PasteboardItem] = []) {
        state = Mutex(State(items: items))
    }

    package func items() -> [PasteboardItem] {
        currentItems
    }

    package func replace(with items: [PasteboardItem]) -> Int {
        state.withLock { state in
            state.items = items
            state.changeCount += 1
            return state.changeCount
        }
    }

    package func data(forType type: String) -> Data? {
        state.withLock { $0.items.first?.representations[type] }
    }

    package func userCopies(_ text: String) {
        _ = replace(with: [.plain(text)])
    }
}

extension PasteboardItem {
    package static func plain(_ text: String) -> PasteboardItem {
        PasteboardItem(representations: [PasteboardType.plainText: Data(text.utf8)])
    }
}
