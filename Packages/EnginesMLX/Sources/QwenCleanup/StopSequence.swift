import Cleanup

internal struct StopSequence: Hashable, Sendable {
    static let tailTokenCount = 8

    let text: String

    init(closing tag: OutputTag) {
        text =
            switch tag {
            case .cleaned: "</cleaned>"
            case .edited: "</edited>"
            }
    }

    func isReached(in decodedTail: String) -> Bool {
        decodedTail.contains(text)
    }
}
