public struct ModelFile: Codable, Hashable, Sendable {
    public let path: String
    public let bytes: Int
    public let sha256: String?

    public init(path: String, bytes: Int, sha256: String?) {
        self.path = path
        self.bytes = bytes
        self.sha256 = sha256
    }
}
