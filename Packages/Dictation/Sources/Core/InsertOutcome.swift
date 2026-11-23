public enum InsertOutcome: Hashable, Sendable {
    case inserted(InsertMethod)
    case copied(CopyReason)
    case refused(RefusalReason)
}
