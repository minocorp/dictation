public struct TargetApp: Hashable, Sendable {
    public let pid: Int32
    public let bundleID: String
    public let name: String

    public init(pid: Int32, bundleID: String, name: String) {
        self.pid = pid
        self.bundleID = bundleID
        self.name = name
    }
}
