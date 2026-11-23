import Cleanup
@testable import QwenCleanup
import Testing

internal struct PrefixProbesTests {
    private func sharedMessageCount(_ probes: [CleanupPrompt]) -> Int {
        zip(probes[0].messages, probes[1].messages).prefix { $0 == $1 }.count
    }

    @Test
    func cleanupProbesShareEverythingBeforeTheRealUserTurn() {
        let probes = PrefixProbes.cleanup(using: PromptBuilder())
        #expect(probes.count == 2)
        #expect(sharedMessageCount(probes) == probes[0].messages.count - 1)
    }

    @Test
    func editProbesShareEverythingBeforeTheRealUserTurn() {
        let probes = PrefixProbes.edit(using: PromptBuilder())
        #expect(probes.count == 2)
        #expect(sharedMessageCount(probes) == probes[0].messages.count - 1)
    }
}
