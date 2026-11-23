internal enum Kind: Equatable, Sendable {
    case dictation
    case editPending
    case edit(selection: String)
}
