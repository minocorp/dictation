public enum UserInitiated {
    public static func run<T: Sendable, E: CancellableError>(
        _ work: @escaping @Sendable () async throws(E) -> T
    ) async throws(E) -> T {
        let task = Task(priority: .userInitiated) { () async -> Result<T, E> in
            do throws(E) {
                return .success(try await work())
            } catch {
                return .failure(error)
            }
        }
        let result = await withTaskCancellationHandler {
            await task.value
        } onCancel: {
            task.cancel()
        }
        return try result.get()
    }
}
