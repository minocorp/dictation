import Foundation
@testable import ModelCatalog
import Testing

internal struct LegacyDownloadCleanupTests {
    private let directory = TestDirectory()

    @Test
    func removesOnlyLeftoverTransferFiles() throws {
        try FileManager.default.createDirectory(
            at: directory.url,
            withIntermediateDirectories: true,
        )
        let leftover = directory.url.appending(path: "CFNetworkDownload_abc.tmp")
        let unrelated = directory.url.appending(path: "keep.txt")
        try Data([1]).write(to: leftover)
        try Data([1]).write(to: unrelated)
        LegacyDownloadCleanup.removeLeftoverTemporaryFiles(in: directory.url)
        #expect(!FileManager.default.fileExists(atPath: leftover.path()))
        #expect(FileManager.default.fileExists(atPath: unrelated.path()))
    }
}
