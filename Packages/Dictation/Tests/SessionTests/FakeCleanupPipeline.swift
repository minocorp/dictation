import Core
@testable import Session
import Synchronization

internal final class FakeCleanupPipeline: CleanupPipeline {
    struct EditCall: Hashable, Sendable {
        let selection: String
        let instruction: String
    }

    private struct State {
        var cleanResult: Result<String, CleanupError> = .success("")
        var editResult: Result<String, CleanupError> = .success("")
        var cleanInputs: [CleanInput] = []
        var editCalls: [EditCall] = []
    }

    private let state = Mutex(State())

    var cleanResult: Result<String, CleanupError> {
        get { state.withLock { $0.cleanResult } }
        set { state.withLock { $0.cleanResult = newValue } }
    }

    var editResult: Result<String, CleanupError> {
        get { state.withLock { $0.editResult } }
        set { state.withLock { $0.editResult = newValue } }
    }

    var cleanInputs: [CleanInput] { state.withLock { $0.cleanInputs } }
    var editCalls: [EditCall] { state.withLock { $0.editCalls } }

    func clean(_ input: CleanInput, dictionary: [Word]) async throws(CleanupError) -> String {
        let result = state.withLock { state in
            state.cleanInputs.append(input)
            return state.cleanResult
        }
        return try result.get()
    }

    func edit(selection: String, instruction: String) async throws(CleanupError) -> String {
        let result = state.withLock { state in
            state.editCalls.append(EditCall(selection: selection, instruction: instruction))
            return state.editResult
        }
        return try result.get()
    }
}
