import Core

internal enum SegmentState: Equatable, Sendable {
    case recorded(Segment)
    case transcribing
    case transcribed(raw: String)
    case cleaning(raw: String)
    case cleaned(raw: String, text: String)

    var rawText: String? {
        switch self {
        case .recorded, .transcribing: nil
        case .transcribed(let raw), .cleaning(let raw), .cleaned(let raw, _): raw
        }
    }

    var cleanedText: String? {
        switch self {
        case .recorded, .transcribing, .transcribed, .cleaning: nil
        case .cleaned(_, let text): text
        }
    }
}
