internal enum FieldEvent: Hashable, Sendable {
    case valueChanged
    case focusLeft
    case appDeactivated
    case timedOut
}
