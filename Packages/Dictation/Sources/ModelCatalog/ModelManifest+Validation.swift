import Core

extension ModelManifest {
    private static let allowedLicenses: Set<String> = [
        "MIT", "Apache-2.0", "BSD-2-Clause", "BSD-3-Clause",
    ]
    private static let revisionLength = 40
    private static let digestLength = 64

    var issues: [ManifestIssue] {
        var found: [ManifestIssue] = []
        if schemaVersion != Self.supportedSchemaVersion {
            found.append(.unsupportedSchemaVersion(schemaVersion))
        }
        var seen: Set<String> = []
        for entry in models {
            if !seen.insert(entry.id).inserted { found.append(.duplicateID(entry.id)) }
            found += Self.issues(of: entry)
        }
        return found
    }

    private static func issues(of entry: ModelEntry) -> [ManifestIssue] {
        var found: [ManifestIssue] = []
        if !entry.id.allSatisfy({
            $0.isASCII && ($0.isLowercase || $0.isNumber || $0 == "." || $0 == "-")
        })
            || entry.id.isEmpty
        {
            found.append(.invalidID(entry.id))
        }
        if entry.format == .builtIn { found.append(.builtInFormat(id: entry.id)) }
        if !allowedLicenses.contains(entry.license) {
            found.append(.disallowedLicense(id: entry.id))
        }
        if entry.repo.split(separator: "/").count != 2 { found.append(.invalidRepo(id: entry.id)) }
        if !isHex(entry.revision, length: revisionLength) {
            found.append(.missingRevision(id: entry.id))
        }
        if entry.files.isEmpty { found.append(.emptyFileList(id: entry.id)) }
        if entry.defaultFor.contains(where: { $0.floorGB < entry.minRAMGB }) {
            found.append(.defaultBelowMinimumRAM(id: entry.id))
        }
        if entry.files.reduce(0, { $0 + $1.bytes }) != entry.downloadBytes {
            found.append(.downloadBytesMismatch(id: entry.id))
        }
        for file in entry.files {
            found += issues(of: file, in: entry)
        }
        return found
    }

    private static func issues(of file: ModelFile, in entry: ModelEntry) -> [ManifestIssue] {
        var found: [ManifestIssue] = []
        let components = file.path.split(separator: "/", omittingEmptySubsequences: false)
        if file.path.isEmpty || file.path.hasPrefix("/")
            || components.contains(where: { $0.isEmpty || $0 == ".." || $0 == "." })
        {
            found.append(.unsafePath(id: entry.id, path: file.path))
        }
        guard let digest = file.sha256 else {
            return found + [.missingHash(id: entry.id, path: file.path)]
        }
        if !isHex(digest, length: digestLength) {
            found.append(.invalidHash(id: entry.id, path: file.path))
        }
        return found
    }

    private static func isHex(_ value: String?, length: Int) -> Bool {
        guard let value, value.count == length else { return false }
        return value.allSatisfy { $0.isHexDigit && !$0.isUppercase }
    }
}
