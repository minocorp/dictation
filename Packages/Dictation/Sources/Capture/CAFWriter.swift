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
            try handle.write(contentsOf: samples.withUnsafeBytes { Data($0) })
        } catch {
            throw .diskWriteFailed(code: (error as NSError).code)
        }
        sampleCount += samples.count
    }

    func finish() throws(CaptureError) {
        do {
            try handle.seek(toOffset: UInt64(CAFFormat.dataSizeOffset))
            let size = CAFFormat.dataChunkSize(sampleCount: sampleCount)
            try handle.write(contentsOf: withUnsafeBytes(of: size.bigEndian) { Data($0) })
            try handle.close()
        } catch {
            throw .diskWriteFailed(code: (error as NSError).code)
        }
    }
}
