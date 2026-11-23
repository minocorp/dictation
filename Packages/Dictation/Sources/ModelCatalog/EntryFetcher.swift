import Core
import Foundation

internal struct EntryFetcher: Sendable {
    private static let host = "huggingface.co"

    let entry: ModelEntry
    let storage: ModelStorage
    let session: TransferSession
    let progress: DownloadProgress

    func fetchMissingFiles() async throws(ModelError) -> FetchOutcome {
        var completedBytes = 0
        progress.report(bytesReceived: 0, force: true)
        for file in entry.files {
            if !storage.hasFile(file, of: entry) {
                guard try await fetch(file, completedBytes: completedBytes) else {
                    return .needsApproval
                }
            }
            completedBytes += file.bytes
            progress.report(bytesReceived: completedBytes, force: true)
        }
        return .completed
    }

    private func fetch(_ file: ModelFile, completedBytes: Int) async throws(ModelError) -> Bool {
        let partial = storage.partialURL(file, of: entry)
        let resume = storage.resumeURL(file, of: entry)
        let progress = progress
        let resumeData = try? Data(contentsOf: resume)
        DownloadLog.fileStarted(file, of: entry, resuming: resumeData != nil)
        let result = await session.download(
            from: try downloadURL(for: file),
            resumeData: resumeData,
            to: partial,
            onProgress: { written in progress.report(bytesReceived: completedBytes + written) },
        )
        switch result {
        case .finished:
            storage.remove(resume)
            try verifyAndInstall(file, partial: partial)
            DownloadLog.fileInstalled(file, of: entry)
            return true
        case .failed(let failure):
            DownloadLog.transferFailed(file, of: entry, code: failure.code)
            return try handle(failure, resume: resume)
        }
    }

    private func handle(_ failure: TransferFailure, resume: URL) throws(ModelError) -> Bool {
        keepResumeData(failure.resumeData, at: resume)
        if failure.isConstrained { return false }
        if failure.isCancelled { throw .cancelled }
        if failure.isOutOfSpace {
            throw .insufficientDiskSpace(requiredBytes: storage.remainingBytes(of: entry))
        }
        throw .networkFailed(code: failure.code)
    }

    private func keepResumeData(_ data: Data?, at url: URL) {
        if let data, (try? data.write(to: url)) != nil { return }
        storage.remove(url)
    }

    private func verifyAndInstall(_ file: ModelFile, partial: URL) throws(ModelError) {
        let size =
            try?
            FileManager.default
            .attributesOfItem(
                atPath: partial.path(percentEncoded: false)
            )[.size] as? Int
        guard size == file.bytes else {
            storage.remove(partial)
            throw .sizeMismatch(path: file.path)
        }
        progress.verifying()
        guard try storage.matchesDigest(file, at: partial) else {
            storage.remove(partial)
            throw .hashMismatch(path: file.path)
        }
        guard !Task.isCancelled else {
            storage.remove(partial)
            throw .cancelled
        }
        try storage.install(file, of: entry, from: partial)
    }

    private func downloadURL(for file: ModelFile) throws(ModelError) -> URL {
        var components = URLComponents()
        components.scheme = "https"
        components.host = Self.host
        components.path = "/\(entry.repo)/resolve/\(entry.revision ?? "")/\(file.path)"
        guard entry.revision != nil, let url = components.url else { throw .unknownModel }
        return url
    }
}
