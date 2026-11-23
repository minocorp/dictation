public import Core

public struct PasteboardClipboardWriter: ClipboardWriter {
    private let transaction: ClipboardTransaction

    public init(transaction: ClipboardTransaction) {
        self.transaction = transaction
    }

    public func copyTransient(_ text: String) async {
        await transaction.copy(text)
    }
}
