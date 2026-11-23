import Foundation

public enum StatusMenu {
    static let lastResultCharacterLimit = 48

    public static func entries(lastResult: String?, canCheckForUpdates: Bool) -> [MenuEntry] {
        let hasResult = lastResult != nil
        return [
            lastResultEntry(lastResult),
            MenuEntry(
                kind: .item(.pasteLast),
                title: UIString.string(UIString.menuPasteLast),
                isEnabled: hasResult,
            ),
            MenuEntry(kind: .separator, title: "", isEnabled: false),
            item(.showHistory, UIString.menuHistory),
            item(.showSettings, UIString.menuSettings),
            item(.showAbout, UIString.menuAbout),
            MenuEntry(
                kind: .item(.checkForUpdates),
                title: UIString.string(UIString.menuCheckForUpdates),
                isEnabled: canCheckForUpdates,
            ),
            MenuEntry(kind: .separator, title: "", isEnabled: false),
            item(.quit, UIString.menuQuit),
        ]
    }

    static func summary(of text: String) -> String {
        let singleLine = text.split(whereSeparator: \.isNewline).joined(separator: " ")
        guard singleLine.count > lastResultCharacterLimit else { return singleLine }
        return String(singleLine.prefix(lastResultCharacterLimit)) + "…"
    }

    private static func lastResultEntry(_ text: String?) -> MenuEntry {
        guard let text else {
            return MenuEntry(
                kind: .label,
                title: UIString.string(UIString.menuLastResultEmpty),
                isEnabled: false,
            )
        }
        guard !text.isEmpty else {
            return MenuEntry(
                kind: .label,
                title: UIString.string(UIString.hudCanceled),
                isEnabled: false,
            )
        }
        return MenuEntry(kind: .item(.copyLastResult), title: summary(of: text), isEnabled: true)
    }

    private static func item(_ action: MenuAction, _ title: LocalizedStringResource) -> MenuEntry {
        MenuEntry(kind: .item(action), title: UIString.string(title), isEnabled: true)
    }
}
