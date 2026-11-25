import Foundation

internal struct TransferFailure: Sendable {
    let code: Int
    let isConstrained: Bool
    let isCancelled: Bool
    let isOutOfSpace: Bool
    let resumeData: Data?
}
