import Core
import Foundation

internal struct DataDirectory: Sendable {
    private static let neverIndexMarker = ".metadata_never_index"
    private static let ownerOnlyPermissions = 0o700

    let root: URL
    let audio: URL

    var databaseFile: URL { root.appending(path: "dictation.sqlite") }

    init(root: URL) {
        self.root = root
        audio = root.appending(path: "Audio", directoryHint: .isDirectory)
    }

    func prepare() throws(StoreError) {
        do {
            try createOwnerOnly(audio)
            try createOwnerOnly(root)
            var values = URLResourceValues()
            values.isExcludedFromBackup = true
            var mutableRoot = root
            try mutableRoot.setResourceValues(values)
            let marker = root.appending(path: Self.neverIndexMarker)
            if !FileManager.default.fileExists(atPath: marker.path(percentEncoded: false)) {
                try Data().write(to: marker)
            }
        } catch {
            throw .file(error)
        }
    }

    private func createOwnerOnly(_ directory: URL) throws {
        let attributes: [FileAttributeKey: Any] = [.posixPermissions: Self.ownerOnlyPermissions]
        try FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true,
            attributes: attributes,
        )
        try FileManager.default.setAttributes(
            attributes,
            ofItemAtPath: directory.path(percentEncoded: false),
        )
    }
}
