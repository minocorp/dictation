import Core

internal struct TrackedTask {
    let id: DictationID?
    let task: Task<Void, Never>
}
