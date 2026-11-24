import Core

extension CleanupPipeline {
    func attempt(
        budget: Duration,
        work: @escaping @Sendable () async throws(CleanupError) -> String,
    ) async throws(CleanupError) -> EngineAttempt {
        let clock = clock
        let result = await withTaskGroup(of: EngineAttempt?.self) { group in
            group.addTask {
                do throws(CleanupError) {
                    return .output(try await work())
                } catch {
                    return .failed(error)
                }
            }
            group.addTask {
                guard await clock.sleepUnlessCancelled(for: budget) else { return nil }
                return .timedOut
            }
            var first: EngineAttempt = .failed(.cancelled)
            for await outcome in group {
                guard let outcome else { continue }
                first = outcome
                break
            }
            group.cancelAll()
            return first
        }
        if case .failed(.cancelled) = result { throw .cancelled }
        return result
    }
}
