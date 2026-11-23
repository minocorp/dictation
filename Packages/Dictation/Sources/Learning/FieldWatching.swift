internal protocol FieldWatching: Sendable {
    func watchFocusedField(ofPID pid: Int32) async -> (any WatchedField)?
}
