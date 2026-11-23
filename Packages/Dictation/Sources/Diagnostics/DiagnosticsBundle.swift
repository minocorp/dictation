public import Core
public import Foundation

public struct DiagnosticsBundle: Sendable {
    public struct File: Hashable, Sendable {
        public let name: String
        public let data: Data
    }

    public let files: [File]

    public var fileNames: [String] { files.map(\.name) }

    public init(files: [File]) {
        self.files = files
    }

    public func write(to destination: URL) throws(DiagnosticsError) {
        let archive = ZipArchive.archive(files.map { ($0.name, $0.data) })
        do {
            try archive.write(to: destination, options: .atomic)
        } catch {
            throw .exportFailed(code: (error as NSError).code)
        }
    }
}
