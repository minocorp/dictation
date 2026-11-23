public struct DownloadProgress: Hashable, Sendable {
    public let receivedBytes: Int
    public let totalBytes: Int

    public var fraction: Double {
        totalBytes > 0 ? min(Double(receivedBytes) / Double(totalBytes), 1) : 0
    }
}
