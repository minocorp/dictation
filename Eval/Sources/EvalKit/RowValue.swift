internal import Foundation

internal enum RowValue: Decodable {
    private struct AudioSource: Decodable {
        let src: URL
    }

    case text(String)
    case audio(URL)
    case other

    init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let text = try? container.decode(String.self) {
            self = .text(text)
        } else if let sources = try? container.decode([AudioSource].self), let first = sources.first
        {
            self = .audio(first.src)
        } else {
            self = .other
        }
    }
}
