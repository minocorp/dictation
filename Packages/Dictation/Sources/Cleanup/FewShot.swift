import Core

internal struct FewShot: Hashable, Sendable {
    let item: Int
    let dictionary: [Word]
    let transcript: String
    let cleaned: String

    init(item: Int, dictionary: [String] = [], transcript: String, cleaned: String) {
        self.item = item
        self.dictionary = dictionary.map { Word(text: $0, soundsLike: [], source: .manual) }
        self.transcript = transcript
        self.cleaned = cleaned
    }
}
