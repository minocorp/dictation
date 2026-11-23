import Foundation

internal enum RecognitionContext {
    static let maximumCharacters = 120

    static func trimmed(_ context: String) -> String {
        let text = context.trimmingCharacters(in: .whitespacesAndNewlines)
        return String(text.suffix(maximumCharacters))
    }
}
