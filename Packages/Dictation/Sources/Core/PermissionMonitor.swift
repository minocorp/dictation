public protocol PermissionMonitor: Sendable {
    var status: AsyncStream<PermissionStatus> { get }

    func request(_ permission: Permission) async
    func openSettings(for permission: Permission) async
}
