public import Foundation

public struct DictationID: Hashable, Sendable, Codable {
    public let rawValue: UUID

    public var stem: String { rawValue.uuidString }

    public init() {
        rawValue = UUID()
    }

    public init(rawValue: UUID) {
        self.rawValue = rawValue
    }

    public init?(stem: String) {
        guard let rawValue = UUID(uuidString: stem) else { return nil }
        self.rawValue = rawValue
    }
}
