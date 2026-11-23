import Cleanup
import Core

internal enum PrefixProbes {
    private static let budget = Duration.seconds(1)

    static func cleanup(using builder: PromptBuilder) -> [CleanupPrompt] {
        let requests = [
            CleanupRequest(
                text: "alpha",
                dictionary: [],
                contextBefore: "",
                languages: [],
                timeBudget: budget,
            ),
            CleanupRequest(
                text: "bravo charlie",
                dictionary: [Word(text: "x", soundsLike: [], source: .manual)],
                contextBefore: "delta",
                languages: [],
                timeBudget: budget,
            ),
        ]
        return requests.map { builder.cleanupPrompt(for: $0, profile: .mlx) }
    }

    static func edit(using builder: PromptBuilder) -> [CleanupPrompt] {
        let requests = [
            EditRequest(selection: "alpha", instruction: "beta", timeBudget: budget),
            EditRequest(selection: "bravo charlie", instruction: "delta echo", timeBudget: budget),
        ]
        return requests.map { builder.editPrompt(for: $0) }
    }
}
