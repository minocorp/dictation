public import Core
public import Foundation

public struct ModelStorage: Sendable {
    private static let partialDirectoryName = ".partial"

    let root: URL

    public init(root: URL) {
        self.root = root
    }

    var partialRoot: URL {
        root.appending(path: Self.partialDirectoryName, directoryHint: .isDirectory)
    }

    public func directory(of entry: ModelEntry) -> URL {
        root.appending(path: entry.id, directoryHint: .isDirectory)
    }

    func fileURL(_ file: ModelFile, of entry: ModelEntry) -> URL {
        directory(of: entry).appending(path: file.path)
    }

    func partialURL(_ file: ModelFile, of entry: ModelEntry) -> URL {
        partialRoot.appending(path: entry.id, directoryHint: .isDirectory)
            .appending(path: file.path.replacing("/", with: "__") + ".part")
    }

    func resumeURL(_ file: ModelFile, of entry: ModelEntry) -> URL {
        partialURL(file, of: entry).appendingPathExtension("resume")
    }

    private var stampRoot: URL {
        root.appending(path: ".verified", directoryHint: .isDirectory)
    }

    private func stampURL(of entry: ModelEntry) -> URL {
        stampRoot.appending(path: "\(entry.id).json")
    }

    func prepare(for entry: ModelEntry) throws(ModelError) {
        do {
            try FileManager.default.createDirectory(
                at: partialRoot.appending(path: entry.id),
                withIntermediateDirectories: true,
            )
            var values = URLResourceValues()
            values.isExcludedFromBackup = true
            var mutableRoot = root
            try mutableRoot.setResourceValues(values)
        } catch {
            throw .file(error, requiredBytes: remainingBytes(of: entry))
        }
    }

    func hasFile(_ file: ModelFile, of entry: ModelEntry) -> Bool {
        let attributes = try? FileManager.default.attributesOfItem(
            atPath: fileURL(file, of: entry).path(percentEncoded: false)
        )
        return (attributes?[.size] as? Int) == file.bytes
    }

    public func isInstalled(_ entry: ModelEntry) -> Bool {
        !entry.files.isEmpty && entry.files.allSatisfy { hasFile($0, of: entry) }
    }

    func remainingBytes(of entry: ModelEntry) -> Int {
        entry.files.filter { !hasFile($0, of: entry) }.reduce(0) { $0 + $1.bytes }
    }

    func install(_ file: ModelFile, of entry: ModelEntry, from partial: URL) throws(ModelError) {
        let destination = fileURL(file, of: entry)
        do {
            try FileManager.default.createDirectory(
                at: destination.deletingLastPathComponent(),
                withIntermediateDirectories: true,
            )
            if FileManager.default.fileExists(atPath: destination.path(percentEncoded: false)) {
                _ = try FileManager.default.replaceItemAt(destination, withItemAt: partial)
            } else {
                try FileManager.default.moveItem(at: partial, to: destination)
            }
            var values = URLResourceValues()
            values.isExcludedFromBackup = true
            var mutableDirectory = directory(of: entry)
            try mutableDirectory.setResourceValues(values)
        } catch {
            throw .file(error, requiredBytes: file.bytes)
        }
        recordStamp(file, of: entry)
    }

    public func verify(_ entry: ModelEntry) throws(ModelError) {
        var stamps = readStamps(of: entry)
        for file in entry.files {
            let url = fileURL(file, of: entry)
            guard hasFile(file, of: entry) else {
                remove(url)
                throw .sizeMismatch(path: file.path)
            }
            if let current = stamp(of: file, at: url), stamps[file.path] == current { continue }
            guard try matchesDigest(file, at: url) else {
                remove(url)
                throw .hashMismatch(path: file.path)
            }
            stamps[file.path] = stamp(of: file, at: url)
        }
        writeStamps(stamps, of: entry)
    }

    func matchesDigest(_ file: ModelFile, at url: URL) throws(ModelError) -> Bool {
        do {
            return try FileDigest.sha256(of: url) == file.sha256
        } catch {
            throw .fileFailed(code: (error as NSError).code)
        }
    }

    private func recordStamp(_ file: ModelFile, of entry: ModelEntry) {
        var stamps = readStamps(of: entry)
        stamps[file.path] = stamp(of: file, at: fileURL(file, of: entry))
        writeStamps(stamps, of: entry)
    }

    private func stamp(of file: ModelFile, at url: URL) -> VerificationStamp? {
        let attributes = try? FileManager.default.attributesOfItem(
            atPath: url.path(percentEncoded: false)
        )
        guard let modified = attributes?[.modificationDate] as? Date else { return nil }
        return VerificationStamp(
            sha256: file.sha256,
            bytes: file.bytes,
            modified: modified.timeIntervalSince1970,
        )
    }

    private func readStamps(of entry: ModelEntry) -> [String: VerificationStamp] {
        guard let data = try? Data(contentsOf: stampURL(of: entry)) else { return [:] }
        return (try? JSONDecoder().decode([String: VerificationStamp].self, from: data)) ?? [:]
    }

    private func writeStamps(_ stamps: [String: VerificationStamp], of entry: ModelEntry) {
        do {
            try FileManager.default.createDirectory(
                at: stampRoot,
                withIntermediateDirectories: true,
            )
            try JSONEncoder().encode(stamps).write(to: stampURL(of: entry), options: .atomic)
        } catch {
            DownloadLog.stampFailed(entry, error: error)
        }
    }

    func remove(_ url: URL) {
        try? FileManager.default.removeItem(at: url)
    }

    public func delete(_ entry: ModelEntry) throws(ModelError) {
        for url in [
            directory(of: entry), partialRoot.appending(path: entry.id), stampURL(of: entry),
        ]
        where FileManager.default.fileExists(atPath: url.path(percentEncoded: false)) {
            do {
                try FileManager.default.removeItem(at: url)
            } catch {
                throw .fileFailed(code: (error as NSError).code)
            }
        }
    }

    public static func availableBytes(at url: URL) -> Int? {
        let values = try? url.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey]
        )
        return values?.volumeAvailableCapacityForImportantUsage.map { Int($0) }
    }
}
