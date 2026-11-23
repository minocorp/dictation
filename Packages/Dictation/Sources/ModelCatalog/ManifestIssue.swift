internal enum ManifestIssue: Hashable, Sendable {
    case unsupportedSchemaVersion(Int)
    case invalidID(String)
    case duplicateID(String)
    case builtInFormat(id: String)
    case disallowedLicense(id: String)
    case invalidRepo(id: String)
    case missingRevision(id: String)
    case emptyFileList(id: String)
    case unsafePath(id: String, path: String)
    case missingHash(id: String, path: String)
    case invalidHash(id: String, path: String)
    case downloadBytesMismatch(id: String)
}
