public import Core
import Synchronization

public final class FakeClipboardWriter: ClipboardWriter {
    private let copiedTexts = Mutex<[String]>([])

    public var copied: [String] { copiedTexts.withLock { $0 } }

    public init() {}

    public func copyTransient(_ text: String) async {
        copiedTexts.withLock { $0.append(text) }
    }
}
