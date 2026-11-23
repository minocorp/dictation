import Foundation

internal struct TransferFailure: Sendable {
    let code: Int
    let isConstrained: Bool
    let isCancelled: Bool
    let isOutOfSpace: Bool
    let resumeData: Data?

    static let cancelled = TransferFailure(
        code: NSURLErrorCancelled,
        isConstrained: false,
        isCancelled: true,
        isOutOfSpace: false,
        resumeData: nil,
    )
}
