import AppKit
import CoreGraphics

@MainActor
internal enum FocusedWindowLocator {
    static func frame() -> CGRect? {
        guard let processIdentifier = NSWorkspace.shared.frontmostApplication?.processIdentifier,
            let primaryHeight = NSScreen.screens.first?.frame.height,
            let windows = CGWindowListCopyWindowInfo(
                [.optionOnScreenOnly, .excludeDesktopElements],
                kCGNullWindowID,
            ) as? [[String: Any]]
        else { return nil }
        for window in windows {
            guard window[kCGWindowOwnerPID as String] as? Int32 == processIdentifier,
                window[kCGWindowLayer as String] as? Int == 0,
                let bounds = window[kCGWindowBounds as String] as? NSDictionary,
                let quartz = CGRect(dictionaryRepresentation: bounds)
            else { continue }
            return CGRect(
                x: quartz.minX,
                y: primaryHeight - quartz.maxY,
                width: quartz.width,
                height: quartz.height,
            )
        }
        return nil
    }
}
