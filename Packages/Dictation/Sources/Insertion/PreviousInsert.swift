internal struct PreviousInsert: Equatable {
    static let maximumAge = Duration.seconds(30)

    let pid: Int32
    let fieldID: Int?
    let text: String
    let insertedAt: ContinuousClock.Instant

    func continues(pid: Int32, fieldID: Int?, at now: ContinuousClock.Instant) -> Bool {
        guard self.pid == pid, insertedAt.duration(to: now) <= Self.maximumAge else { return false }
        guard let previousField = self.fieldID, let currentField = fieldID else { return true }
        return previousField == currentField
    }
}
