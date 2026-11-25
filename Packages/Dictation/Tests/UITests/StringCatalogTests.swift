import Foundation
import Testing

internal struct StringCatalogTests {
    private static let languages = ["en", "ko"]

    private static var uiSources: URL {
        URL(filePath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appending(path: "Sources/UI")
    }

    private static func catalog() throws -> [String: [String: String]] {
        let url = uiSources.appending(path: "Resources/Localizable.xcstrings")
        let root = try JSONSerialization.jsonObject(with: Data(contentsOf: url))
        let strings = (root as? [String: Any])?["strings"] as? [String: Any] ?? [:]
        return strings.mapValues { entry in
            let localizations = (entry as? [String: Any])?["localizations"] as? [String: Any]
            return (localizations ?? [:])
                .compactMapValues { localization in
                    let unit = (localization as? [String: Any])?["stringUnit"] as? [String: Any]
                    return unit?["value"] as? String
                }
        }
    }

    private static func declaredKeys() throws -> Set<String> {
        let directory = uiSources.appending(path: "Strings")
        let files = try FileManager.default.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: nil,
        )
        let pattern = /resource\("(\w+)"\)/
        var keys: Set<String> = []
        for file in files where file.pathExtension == "swift" {
            let source = try String(contentsOf: file, encoding: .utf8)
            for match in source.matches(of: pattern) { keys.insert(String(match.output.1)) }
        }
        return keys
    }

    @Test
    func everyEntryIsTranslated() throws {
        for (key, values) in try Self.catalog() {
            for language in Self.languages {
                let value = values[language] ?? ""
                #expect(!value.isEmpty, "\(key) has no \(language) text")
            }
        }
    }

    @Test
    func declaredKeysAndCatalogMatch() throws {
        let catalogKeys = Set(try Self.catalog().keys.filter { !$0.contains("%") })
        let declared = try Self.declaredKeys()
        #expect(declared.subtracting(catalogKeys).isEmpty)
        #expect(catalogKeys.subtracting(declared).isEmpty)
    }
}
