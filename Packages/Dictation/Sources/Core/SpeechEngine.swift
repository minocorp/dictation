public import Foundation

public protocol SpeechEngine: Sendable {
    func prepare() async throws(SpeechError)
    func transcribe(
        _ segment: Segment,
        context: String,
        languages: [Locale],
    ) async throws(SpeechError) -> String
    func preheat() async
    func unload() async
}
