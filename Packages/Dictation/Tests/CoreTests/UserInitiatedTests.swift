@testable import Core
import Testing

internal struct UserInitiatedTests {
    @Test
    func runsTheWorkAtUserInitiatedPriority() async {
        let priority = await Task(priority: .background) { () async -> TaskPriority in
            do throws(SpeechError) {
                return try await UserInitiated.run { () async throws(SpeechError) -> TaskPriority in
                    Task.currentPriority
                }
            } catch {
                return .background
            }
        }
        .value
        #expect(priority >= .userInitiated)
    }

    @Test
    func rethrowsTheWorkErrorUnchanged() async {
        do throws(SpeechError) {
            try await UserInitiated.run { () async throws(SpeechError) in
                throw SpeechError.modelUnavailable
            }
            Issue.record("expected an error")
        } catch {
            #expect(error == .modelUnavailable)
        }
    }

    @Test
    func forwardsCancellationToTheWork() async {
        let task = Task { () async -> Bool in
            do throws(SpeechError) {
                return try await UserInitiated.run { () async throws(SpeechError) -> Bool in
                    while !Task.isCancelled { await Task.yield() }
                    return true
                }
            } catch {
                return false
            }
        }
        await Task.yield()
        task.cancel()
        #expect(await task.value)
    }
}
