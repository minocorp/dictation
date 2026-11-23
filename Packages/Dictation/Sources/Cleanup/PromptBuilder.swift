public import Core
import Foundation

public struct PromptBuilder: Sendable {
    public static let dictionaryLimit = 50
    public static let beforeCursorLimit = 200
    public static let foundationModelsTranscriptTokenLimit = 800

    private static let cleanupPrefill = "<cleaned>"
    private static let editPrefill = "<edited>"

    private let tokenCounter: any TokenCounting
    private let sanitizer = PromptSanitizer()

    public init(tokenCounter: any TokenCounting = ApproximateTokenCounter()) {
        self.tokenCounter = tokenCounter
    }

    public func cleanupPrompt(
        for request: CleanupRequest,
        profile: CleanupProfile,
    ) -> CleanupPrompt {
        let shots =
            switch profile {
            case .mlx: CleanupFewShots.all
            case .foundationModels:
                CleanupFewShots.all.filter {
                    CleanupFewShots.foundationModelsItems.contains($0.item)
                }
            }
        var messages = [PromptMessage(role: .system, content: PromptText.cleanupSystem)]
        for shot in shots {
            messages.append(
                PromptMessage(role: .user, content: wrap(shot.transcript, shot.dictionary, ""))
            )
            messages.append(
                PromptMessage(role: .assistant, content: "<cleaned>\(shot.cleaned)</cleaned>")
            )
        }
        let user = wrap(request.text, request.dictionary, request.contextBefore)
        messages.append(PromptMessage(role: .user, content: user))
        let inputTokens = tokenCounter.tokenCount(of: request.text)
        return CleanupPrompt(
            messages: messages,
            assistantPrefill: Self.cleanupPrefill,
            temperature: 0,
            maximumTokens: min(768, Int((1.4 * Double(inputTokens)).rounded(.up)) + 24),
        )
    }

    public func editPrompt(for request: EditRequest) -> CleanupPrompt {
        var messages = [PromptMessage(role: .system, content: PromptText.editSystem)]
        for shot in EditFewShot.all {
            messages.append(
                PromptMessage(role: .user, content: wrapEdit(shot.selection, shot.instruction))
            )
            messages.append(
                PromptMessage(role: .assistant, content: "<edited>\(shot.edited)</edited>")
            )
        }
        messages.append(
            PromptMessage(role: .user, content: wrapEdit(request.selection, request.instruction))
        )
        let selectionTokens = tokenCounter.tokenCount(of: request.selection)
        return CleanupPrompt(
            messages: messages,
            assistantPrefill: Self.editPrefill,
            temperature: 0.2,
            maximumTokens: min(1024, 2 * selectionTokens + 64),
        )
    }

    public func renderedDictionary(_ words: [Word], relevantTo transcript: String = "") -> String {
        guard words.count > Self.dictionaryLimit else {
            return words.map(\.text).joined(separator: ", ")
        }
        let spoken = transcript.lowercased()
        var mentioned: [Word] = []
        var others: [Word] = []
        for word in words {
            if Self.isMentioned(word, in: spoken) {
                mentioned.append(word)
            } else {
                others.append(word)
            }
        }
        return (mentioned + others).prefix(Self.dictionaryLimit).map(\.text)
            .joined(separator: ", ")
    }

    private static func isMentioned(_ word: Word, in spoken: String) -> Bool {
        guard !spoken.isEmpty else { return false }
        return ([word.text] + word.soundsLike)
            .contains {
                !$0.isEmpty && spoken.contains($0.lowercased())
            }
    }

    private func wrap(
        _ transcript: String,
        _ dictionary: [Word],
        _ contextBefore: String,
    ) -> String {
        let context = String(contextBefore.suffix(Self.beforeCursorLimit))
        return [
            "<dictionary>\(sanitizer.stripped(renderedDictionary(dictionary, relevantTo: transcript)))</dictionary>",
            "<before_cursor>\(sanitizer.stripped(context))</before_cursor>",
            "<transcript>\(sanitizer.stripped(transcript))</transcript>",
        ]
        .joined(separator: "\n")
    }

    private func wrapEdit(_ selection: String, _ instruction: String) -> String {
        [
            "<selection>\(sanitizer.stripped(selection))</selection>",
            "<instruction>\(sanitizer.stripped(instruction))</instruction>",
        ]
        .joined(separator: "\n")
    }
}
