public import Core
public import Foundation

public struct ModelManifest: Codable, Hashable, Sendable {
    static let supportedSchemaVersion = 1

    private enum CodingKeys: String, CodingKey {
        case schemaVersion = "schema_version"
        case models
    }

    public let schemaVersion: Int
    public let models: [ModelEntry]

    public init(schemaVersion: Int, models: [ModelEntry]) {
        self.schemaVersion = schemaVersion
        self.models = models
    }

    public static func bundled() throws(ModelError) -> ModelManifest {
        guard let url = Bundle.module.url(forResource: "manifest", withExtension: "json") else {
            throw .loadFailed
        }
        return try load(from: url)
    }

    public static func load(from url: URL) throws(ModelError) -> ModelManifest {
        let data: Data
        do {
            data = try Data(contentsOf: url)
        } catch {
            throw .fileFailed(code: (error as NSError).code)
        }
        return try decode(data)
    }

    public static func decode(_ data: Data) throws(ModelError) -> ModelManifest {
        let manifest: ModelManifest
        do {
            manifest = try JSONDecoder().decode(ModelManifest.self, from: data)
        } catch {
            throw .loadFailed
        }
        guard manifest.issues.isEmpty else { throw .loadFailed }
        return manifest
    }

    func entries(stage: ModelStage) -> [ModelEntry] {
        models.filter { $0.stage == stage }
    }

    func entry(id: String) -> ModelEntry? {
        models.first { $0.id == id }
    }
}
