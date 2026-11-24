extension Clock where Duration == Swift.Duration {
    public func sleepUnlessCancelled(for duration: Duration) async -> Bool {
        do {
            try await sleep(for: duration)
            return true
        } catch {
            return false
        }
    }
}
