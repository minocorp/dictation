import Foundation

internal struct VerificationStamp: Codable, Equatable, Sendable {
    let sha256: String?
    let bytes: Int
    let modified: TimeInterval
}
