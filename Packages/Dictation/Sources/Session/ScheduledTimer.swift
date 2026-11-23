internal struct ScheduledTimer {
    let generation: Int
    let task: Task<Void, Never>
}
