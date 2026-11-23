import Foundation

internal enum TransferResult: Sendable {
    case finished
    case failed(TransferFailure)
}
