internal struct LanguageCues: Hashable, Sendable {
    let en: [String]
    let ko: [String]

    var all: [String] { en + ko }
}
