public struct ModelEntry: Codable, Hashable, Sendable, Identifiable {
    private enum CodingKeys: String, CodingKey {
        case id
        case stage
        case displayName = "display_name"
        case family
        case repo
        case revision
        case observedRevision = "observed_revision"
        case format
        case quant
        case license
        case licenseVerified = "license_verified"
        case languages
        case minRAMGB = "min_ram_gb"
        case downloadBytes = "download_bytes"
        case files
        case defaultFor = "default_for"
        case runtime
        case verified
        case unverified
    }

    public let id: String
    public let stage: ModelStage
    public let displayName: String
    public let family: String
    public let repo: String
    public let revision: String?
    public let observedRevision: String?
    public let format: ModelFormat
    public let quant: String
    public let license: String
    public let licenseVerified: Bool
    public let languages: [String]
    public let minRAMGB: Int
    public let downloadBytes: Int
    public let files: [ModelFile]
    public let defaultFor: [RAMTier]
    public let runtime: String?
    public let verified: [String]
    public let unverified: [String]?

    public var isDownloadable: Bool { format != .builtIn }

    public init(
        id: String,
        stage: ModelStage,
        displayName: String,
        family: String,
        repo: String,
        revision: String?,
        observedRevision: String?,
        format: ModelFormat,
        quant: String,
        license: String,
        licenseVerified: Bool,
        languages: [String],
        minRAMGB: Int,
        downloadBytes: Int,
        files: [ModelFile],
        defaultFor: [RAMTier],
        runtime: String?,
        verified: [String],
        unverified: [String]?,
    ) {
        self.id = id
        self.stage = stage
        self.displayName = displayName
        self.family = family
        self.repo = repo
        self.revision = revision
        self.observedRevision = observedRevision
        self.format = format
        self.quant = quant
        self.license = license
        self.licenseVerified = licenseVerified
        self.languages = languages
        self.minRAMGB = minRAMGB
        self.downloadBytes = downloadBytes
        self.files = files
        self.defaultFor = defaultFor
        self.runtime = runtime
        self.verified = verified
        self.unverified = unverified
    }
}
