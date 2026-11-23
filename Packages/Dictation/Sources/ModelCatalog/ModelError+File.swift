import Core
import Foundation

extension ModelError {
    static func file(_ error: any Error, requiredBytes: Int) -> ModelError {
        isOutOfSpace(error)
            ? .insufficientDiskSpace(requiredBytes: requiredBytes)
            : .fileFailed(code: (error as NSError).code)
    }

    static func isOutOfSpace(_ error: any Error) -> Bool {
        let nsError = error as NSError
        let isCocoa = nsError.domain == NSCocoaErrorDomain
        let isPOSIX = nsError.domain == NSPOSIXErrorDomain
        if isCocoa && nsError.code == NSFileWriteOutOfSpaceError { return true }
        if isPOSIX && nsError.code == Int(ENOSPC) { return true }
        guard let underlying = nsError.userInfo[NSUnderlyingErrorKey] as? NSError else {
            return false
        }
        return isOutOfSpace(underlying)
    }
}
