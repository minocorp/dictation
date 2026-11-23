import Foundation

internal struct PromptSanitizer: Sendable {
    private static let forbiddenLiterals = [
        "<transcript>", "</transcript>", "<cleaned>", "</cleaned>", "<dictionary>",
        "</dictionary>", "<before_cursor>", "</before_cursor>", "<selection>", "</selection>",
        "<instruction>", "</instruction>", "<edited>", "</edited>",
    ]
    private let specialTokens = Pattern("<\\|.*?\\|>")

    func stripped(_ text: String) -> String {
        var current = text
        while true {
            var next = specialTokens.replacing(in: current, with: "")
            for literal in Self.forbiddenLiterals {
                next = next.replacingOccurrences(of: literal, with: "")
            }
            if next == current { return next }
            current = next
        }
    }
}
