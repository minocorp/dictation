import Core

internal enum InsertionEvidence {
    case confirmed
    case unchanged
    case unreadable
    case targetGone

    func provesFailure(in kind: FieldKind) -> Bool {
        switch self {
        case .confirmed, .unreadable: false
        case .unchanged: kind == .singleLine
        case .targetGone: true
        }
    }
}
