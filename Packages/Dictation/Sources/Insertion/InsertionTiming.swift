internal enum InsertionTiming {
    static let modifierWait: Duration = .milliseconds(300)
    static let modifierPoll: Duration = .milliseconds(10)
    static let composingWait: Duration = .milliseconds(1_500)
    static let composingPoll: Duration = .milliseconds(50)
    static let evidenceWait: Duration = .milliseconds(200)
    static let lateEvidenceWait: Duration = .milliseconds(800)
    static let evidencePoll: Duration = .milliseconds(25)

    static func polls(in wait: Duration, every interval: Duration) -> Int {
        Int(wait / interval)
    }
}
