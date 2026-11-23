public protocol TextInserter: Sendable {
    func insert(
        _ text: String,
        into target: TargetApp,
        focus: FocusSnapshot,
    ) async
        -> InsertOutcome
}
