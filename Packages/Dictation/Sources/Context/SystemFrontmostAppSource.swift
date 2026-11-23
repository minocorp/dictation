import AppKit
import Core

internal struct SystemFrontmostAppSource: FrontmostAppSource {
    func frontmost() -> TargetApp? {
        guard let application = NSWorkspace.shared.frontmostApplication else { return nil }
        return TargetApp(
            pid: application.processIdentifier,
            bundleID: application.bundleIdentifier ?? "",
            name: application.localizedName ?? "",
        )
    }
}
