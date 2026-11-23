internal enum TerminalApplications {
    private static let bundleIDs: Set<String> = [
        "com.apple.Terminal",
        "com.googlecode.iterm2",
        "com.mitchellh.ghostty",
        "net.kovidgoyal.kitty",
        "org.alacritty",
        "dev.warp.Warp-Stable",
        "com.github.wez.wezterm",
        "co.zeit.hyper",
    ]

    static func contains(_ bundleID: String) -> Bool {
        bundleIDs.contains(bundleID)
    }
}
