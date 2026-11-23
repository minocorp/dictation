public import Core
public import Foundation

public struct DiagnosticsPackage: Sendable {
    let fileNames: [String]
    let write: @Sendable (URL) throws(DiagnosticsError) -> Void

    public init(
        fileNames: [String],
        write: @escaping @Sendable (URL) throws(DiagnosticsError) -> Void,
    ) {
        self.fileNames = fileNames
        self.write = write
    }
}
