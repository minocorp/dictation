import Core
import Foundation
import Testing

internal struct ModelEntryTests {
    private static let manifestEntry = """
        {
          "id": "qwen3-asr-0.6b-4bit", "stage": "speech", "display_name": "Qwen3-ASR 0.6B (4-bit)", "family": "qwen3-asr",
          "repo": "mlx-community/Qwen3-ASR-0.6B-4bit", "revision": null, "observed_revision": "313d850181767edf09f00a9c289becca70e58cd0",
          "format": "mlx-safetensors", "quant": "4bit", "license": "Apache-2.0", "license_verified": true,
          "languages": ["multilingual", "ko", "en"], "min_ram_gb": 8, "download_bytes": 715000000,
          "files": [], "default_for": ["ram-16"], "runtime": "mlx-audio-swift (MLXAudioSTT, Qwen3-ASR), spike 4",
          "verified": ["repo exists", "license tag apache-2.0", "model.safetensors 708236945 bytes"],
          "unverified": ["Korean quality at 4-bit vs 8-bit"]
        }
        """

    private static let pinnedEntry = """
        {
          "id": "qwen3.5-2b-4bit", "stage": "cleanup", "display_name": "Qwen3.5 2B (4-bit)", "family": "qwen3.5",
          "repo": "mlx-community/Qwen3.5-2B-4bit", "revision": "674aaa7240b91e8012fcad5d791b7dfe5ba90207",
          "format": "mlx-safetensors", "quant": "4bit", "license": "Apache-2.0", "license_verified": true,
          "languages": ["multilingual"], "min_ram_gb": 16, "download_bytes": 1749000000,
          "files": [
            {"path": "model.safetensors", "bytes": 1749081927, "sha256": "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef"},
            {"path": "config.json", "bytes": 1024, "sha256": null}
          ],
          "default_for": ["ram-16", "ram-24"], "verified": ["repo exists"]
        }
        """

    @Test
    func decodesManifestEntry() throws {
        let entry = try decode(Self.manifestEntry)
        #expect(entry.id == "qwen3-asr-0.6b-4bit")
        #expect(entry.stage == .speech)
        #expect(entry.displayName == "Qwen3-ASR 0.6B (4-bit)")
        #expect(entry.revision == nil)
        #expect(entry.observedRevision == "313d850181767edf09f00a9c289becca70e58cd0")
        #expect(entry.format == .mlxSafetensors)
        #expect(entry.licenseVerified)
        #expect(entry.minRAMGB == 8)
        #expect(entry.downloadBytes == 715_000_000)
        #expect(entry.defaultFor == [.ram16])
        #expect(entry.files.isEmpty)
        #expect(entry.isDownloadable)
    }

    @Test
    func decodesPinnedEntryWithFilesAndMissingOptionals() throws {
        let entry = try decode(Self.pinnedEntry)
        #expect(entry.revision == "674aaa7240b91e8012fcad5d791b7dfe5ba90207")
        #expect(entry.observedRevision == nil)
        #expect(entry.runtime == nil)
        #expect(entry.unverified == nil)
        #expect(entry.defaultFor == [.ram16, .ram24])
        #expect(
            entry.files.map(\.sha256) == [String(repeating: "0123456789abcdef", count: 4), nil]
        )
    }

    @Test(arguments: [manifestEntry, pinnedEntry])
    func roundTripsThroughJSON(json: String) throws {
        let entry = try decode(json)
        let encoded = try JSONEncoder().encode(entry)
        #expect(try JSONDecoder().decode(ModelEntry.self, from: encoded) == entry)
    }

    @Test
    func encodesSnakeCaseKeys() throws {
        let encoded = try JSONEncoder().encode(try decode(Self.manifestEntry))
        let object = try #require(try JSONSerialization.jsonObject(with: encoded) as? [String: Any])
        #expect(object["display_name"] as? String == "Qwen3-ASR 0.6B (4-bit)")
        #expect(object["min_ram_gb"] as? Int == 8)
        #expect(object["default_for"] as? [String] == ["ram-16"])
    }

    @Test
    func builtInEntriesAreNotDownloadable() {
        #expect(!ModelEntry.appleSpeechAnalyzer.isDownloadable)
        #expect(!ModelEntry.appleFoundationModels.isDownloadable)
        #expect(ModelEntry.appleSpeechAnalyzer.stage == .speech)
        #expect(ModelEntry.appleFoundationModels.stage == .cleanup)
        #expect(ModelEntry.appleSpeechAnalyzer.id == "apple-speechanalyzer")
        #expect(ModelEntry.appleFoundationModels.id == "apple-foundation-models")
    }

    private func decode(_ json: String) throws -> ModelEntry {
        try JSONDecoder().decode(ModelEntry.self, from: Data(json.utf8))
    }
}
