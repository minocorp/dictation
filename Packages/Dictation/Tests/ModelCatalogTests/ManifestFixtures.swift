import Core
import Foundation

internal enum ManifestFixtures {
    static var realManifestURL: URL {
        var directory = URL(filePath: #filePath).deletingLastPathComponent()
        while directory.path() != "/" {
            let candidate = directory.appending(path: "Models/manifest.json")
            if FileManager.default.fileExists(atPath: candidate.path()) { return candidate }
            directory.deleteLastPathComponent()
        }
        return directory
    }

    static func entry(
        id: String = "test-model",
        stage: ModelStage = .speech,
        format: ModelFormat = .mlxSafetensors,
        license: String = "Apache-2.0",
        repo: String = "owner/name",
        revision: String? = String(repeating: "a", count: 40),
        files: [ModelFile] = [
            ModelFile(path: "model.bin", bytes: 10, sha256: String(repeating: "b", count: 64))
        ],
        downloadBytes: Int = 10,
        minRAMGB: Int = 8,
        defaultFor: [RAMTier] = [],
    ) -> ModelEntry {
        ModelEntry(
            id: id,
            stage: stage,
            displayName: id,
            family: "test",
            repo: repo,
            revision: revision,
            observedRevision: nil,
            format: format,
            quant: "4bit",
            license: license,
            licenseVerified: true,
            languages: ["multilingual", "ko", "en"],
            minRAMGB: minRAMGB,
            downloadBytes: downloadBytes,
            files: files,
            defaultFor: defaultFor,
            runtime: nil,
            verified: [],
            unverified: nil,
        )
    }
}
