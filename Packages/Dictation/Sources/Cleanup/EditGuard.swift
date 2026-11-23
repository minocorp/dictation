import Foundation

internal struct EditGuard: Sendable {
    private static let lengthMultiplier = 4
    private static let lengthAllowance = 400
    private static let fence = "```"

    private let replyDetector = ReplyDetector()

    func verify(selection: String, output: String) -> GuardFailure? {
        let trimmed = output.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return .emptyOutput }
        if replyDetector.hasReplyOpener(output, input: selection) { return .replyPattern }
        if replyDetector.hasEditTag(output) || hasForeignFence(trimmed, selection: selection) {
            return .structureLeak
        }
        let limit = Self.lengthMultiplier * selection.count + Self.lengthAllowance
        return output.count > limit ? .lengthRatio : nil
    }

    private func hasForeignFence(_ output: String, selection: String) -> Bool {
        let trimmed = selection.trimmingCharacters(in: .whitespacesAndNewlines)
        let hasLeading = output.hasPrefix(Self.fence) && !trimmed.hasPrefix(Self.fence)
        let hasTrailing = output.hasSuffix(Self.fence) && !trimmed.hasSuffix(Self.fence)
        return hasLeading || hasTrailing
    }
}
