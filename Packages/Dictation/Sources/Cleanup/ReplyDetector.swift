import Foundation

public struct ReplyDetector: Sendable {
    private let openers = [
        Pattern(
            "^(sure|certainly|of course|absolutely|okay|ok|great question|here('s| is| are)"
                + "|i('m| am) (sorry|unable|not able)|i can('t|not)|i cannot|as an ai|let me)\\b"
        ),
        Pattern("^(네|물론|알겠|죄송|제가|도와|다음과 같|여기)"),
        Pattern("^(답변|정답|결과)\\s*[:：]"),
    ]
    private let structure = [
        Pattern("\\*\\*"),
        Pattern("^#{1,6}\\s", multiline: true),
        Pattern("^\\s*(note|output|참고|설명)\\s*[:：]", multiline: true),
    ]
    private let listItem = Pattern.numberedListMarker
    private let tag = Pattern("</?[A-Za-z][A-Za-z0-9_]*(\\s[^>]*)?>", caseInsensitive: false)

    public init() {}

    public func hasReplyOpener(_ output: String, input: String) -> Bool {
        let trimmed = output.trimmingCharacters(in: .whitespacesAndNewlines)
        let lowercasedInput = input.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return openers.contains { pattern in
            guard let opener = pattern.firstMatchedString(in: trimmed) else { return false }
            return !lowercasedInput.hasPrefix(opener.lowercased())
        }
    }

    public func hasForeignStructure(_ output: String, input: String) -> Bool {
        if isSingleItemList(output), !listItem.contains(in: input) { return true }
        return structure.contains { $0.contains(in: output) }
            || tag.matchedStrings(in: output).contains { !input.contains($0) }
    }

    private func isSingleItemList(_ output: String) -> Bool {
        listItem.matches(in: output).count == 1
    }

    func hasEditTag(_ output: String) -> Bool {
        ["<selection", "<instruction", "<edited"].contains { output.contains($0) }
    }
}
