import Core
import Foundation

internal final class CAFWriter {
    let url: URL

    private let handle: FileHandle
    private var sampleCount = 0

    init(url: URL) throws(CaptureError) {
        self.url = url
        let created = FileManager.default.createFile(
            atPath: url.path(percentEncoded: false),
            contents: CAFFormat.header(),
            attributes: [.posixPermissions: 0o600],
        )
        guard created else { throw .diskWriteFailed(code: CocoaError.fileWriteUnknown.rawValue) }
        do {
            handle = try FileHandle(forWritingTo: url)
            try handle.seekToEnd()
        } catch {
            throw .diskWriteFailed(code: (error as NSError).code)
        }
    }

    func append(_ samples: [Float]) throws(CaptureError) {
        guard !samples.isEmpty else { return }
        do {
            try samples.withUnsafeBytes { try handle.write(contentsOf: $0) }
        } catch {
            throw .diskWriteFailed(code: (error as NSError).code)
        }
        sampleCount += samples.count
    }

    func finish() throws(CaptureError) {
        let sealed = Result { try seal() }
        let closed = Result { try handle.close() }
        do {
            try sealed.get()
            try closed.get()
        } catch {
            throw .diskWriteFailed(code: (error as NSError).code)
        }
    }

    private func seal() throws {
        try handle.seek(toOffset: UInt64(CAFFormat.dataSizeOffset))
        let size = CAFFormat.dataChunkSize(sampleCount: sampleCount)
        try withUnsafeBytes(of: size.bigEndian) { try handle.write(contentsOf: $0) }
        try handle.synchronize()
    }
}
