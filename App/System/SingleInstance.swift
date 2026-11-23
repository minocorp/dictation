import AppKit

@MainActor
internal enum SingleInstance {
    static let openSettingsNotification = Notification.Name("app.dictation.openSettings")

    static func yieldToRunningInstance() -> Bool {
        guard let identifier = Bundle.main.bundleIdentifier else { return false }
        let others = NSRunningApplication.runningApplications(withBundleIdentifier: identifier)
            .filter { $0.processIdentifier != ProcessInfo.processInfo.processIdentifier }
        guard !others.isEmpty else { return false }
        DistributedNotificationCenter.default()
            .postNotificationName(
                openSettingsNotification,
                object: nil,
                userInfo: nil,
                deliverImmediately: true,
            )
        return true
    }
}
