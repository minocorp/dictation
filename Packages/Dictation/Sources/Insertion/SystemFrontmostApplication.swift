import AppKit

internal struct SystemFrontmostApplication: FrontmostApplication {
    func frontmostPID() -> Int32? {
        NSWorkspace.shared.frontmostApplication?.processIdentifier
    }
}
