import Foundation
import Speech

internal enum SupportedLanguages {
    static func load() async -> [Locale] {
        let supported = await SpeechTranscriber.supportedLocales
        var seen = Set<String>()
        return
            supported
            .filter { seen.insert($0.identifier).inserted }
            .sorted { $0.identifier < $1.identifier }
    }
}
