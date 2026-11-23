import Core
import Foundation
import GRDB

extension StoreError {
    enum Access {
        case read
        case write
    }

    static func make(_ error: any Error, access: Access) -> StoreError {
        if let storeError = error as? StoreError { return storeError }
        if error is CancellationError { return .cancelled }
        if case RecordError.recordNotFound = error { return .notFound }
        let code =
            (error as? DatabaseError).map { Int($0.extendedResultCode.rawValue) }
            ?? (error as NSError).code
        return switch access {
        case .read: .readFailed(code: code)
        case .write: .writeFailed(code: code)
        }
    }

    static func file(_ error: any Error) -> StoreError {
        .fileFailed(code: (error as NSError).code)
    }
}
