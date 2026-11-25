public import Core

extension CleanupPipeline {
    public func edit(
        selection: String,
        instruction: String,
    ) async throws(CleanupError) -> EditOutcome {
        let request = EditRequest(
            selection: selection,
            instruction: rules.ruleCleaned(instruction),
        )
        switch try await attempt(
            budget: budget.edit,
            work: { [engine] () async throws(CleanupError) -> String in
                try await engine.edit(request)
            },
        ) {
        case .output(let text):
            guard let failure = editGuard.verify(selection: selection, output: text) else {
                return .edited(text)
            }
            return .unchanged(.guardFailed(failure))
        case .timedOut:
            return .unchanged(.timedOut)
        case .failed(let error):
            return .unchanged(.engine(error))
        }
    }
}
