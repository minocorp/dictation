import Foundation

internal enum ResponsiveProcess {
    static func begin() -> any NSObjectProtocol {
        ProcessInfo.processInfo.beginActivity(
            options: .userInitiatedAllowingIdleSystemSleep,
            reason: "Dictation answers the dictate key without App Nap delay",
        )
    }
}
