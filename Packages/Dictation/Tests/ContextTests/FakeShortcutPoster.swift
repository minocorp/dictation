import Pasteboard
import Synchronization

internal final class FakeShortcutPoster: ShortcutPosting {
    private let postCount = Mutex(0)
    private let result: Bool
    private let onPost: @Sendable () -> Void

    var posts: Int { postCount.withLock { $0 } }

    init(result: Bool = true, onPost: @escaping @Sendable () -> Void = {}) {
        self.result = result
        self.onPost = onPost
    }

    func post(_ shortcut: ClipboardShortcut) async -> Bool {
        postCount.withLock { $0 += 1 }
        onPost()
        return result
    }
}
