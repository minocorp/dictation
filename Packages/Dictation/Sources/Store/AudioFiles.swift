import Core
import Foundation

internal struct AudioFiles: Sendable {
    static let fileExtension = "caf"

    let directory: URL

    func remove(_ url: URL) throws(StoreError) {
        do {
            try FileManager.default.removeItem(at: url)
        } catch let error as NSError where error.code == NSFileNoSuchFileError {
            return
        } catch {
            throw .file(error)
        }
    }

    func remove(fileNames: [String]) throws(StoreError) {
        for name in fileNames {
            try remove(directory.appending(path: name))
        }
    }

    func fileNames() throws(StoreError) -> [String] {
        let path = directory.path(percentEncoded: false)
        guard FileManager.default.fileExists(atPath: path) else { return [] }
        do {
            return try FileManager.default.contentsOfDirectory(atPath: path)
                .filter { URL(filePath: $0).pathExtension == Self.fileExtension }
                .sorted()
        } catch {
            throw .file(error)
        }
    }
}
