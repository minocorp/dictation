import Cleanup
import Core

internal enum PrefixProbes {
    static func cleanup(using builder: PromptBuilder) -> [CleanupPrompt] {
        let requests = [
            CleanupRequest(
                text: "alpha",
                dictionary: [],
                contextBefore: "",
                languages: [],
            ),
            CleanupRequest(
                text: "bravo charlie",
                dictionary: [Word(text: "x", soundsLike: [], source: .manual)],
                contextBefore: "delta",
                languages: [],
            ),
        ]
        return requests.map { builder.cleanupPrompt(for: $0, profile: .mlx) }
    }

    static func edit(using builder: PromptBuilder) -> [CleanupPrompt] {
        let requests = [
            EditRequest(selection: "alpha", instruction: "beta"),
            EditRequest(selection: "bravo charlie", instruction: "delta echo"),
        ]
        return requests.map { builder.editPrompt(for: $0) }
    }
}
