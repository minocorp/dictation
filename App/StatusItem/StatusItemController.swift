import AppKit
import Core
import Session
import UI

@MainActor
internal final class StatusItemController: NSObject, NSMenuDelegate {
    private let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let runner: SessionRunner
    private let downloads: ModelDownloads
    private let canCheckForUpdates: @MainActor () -> Bool
    private let perform: @MainActor (MenuAction) -> Void
    private var actions: [MenuAction] = []
    private var watching: Task<Void, Never>?

    init(
        runner: SessionRunner,
        downloads: ModelDownloads,
        canCheckForUpdates: @escaping @MainActor () -> Bool,
        perform: @escaping @MainActor (MenuAction) -> Void,
    ) {
        self.runner = runner
        self.downloads = downloads
        self.canCheckForUpdates = canCheckForUpdates
        self.perform = perform
        super.init()
        let menu = NSMenu()
        menu.delegate = self
        item.menu = menu
        show(.idle)
    }

    isolated deinit {
        watching?.cancel()
        NSStatusBar.system.removeStatusItem(item)
    }

    func start() {
        watching = Task { [weak self] in
            guard let self else { return }
            let runner = runner
            let downloads = downloads
            let icons = Observations {
                StatusIcon.resolve(
                    hud: runner.state.hud,
                    permissions: runner.state.permissions,
                    isDownloading: downloads.isDownloading,
                )
            }
            for await icon in icons {
                self.show(icon)
            }
        }
    }

    #if DEBUG
    func popUpMenu() {
        item.button?.performClick(nil)
    }
    #endif

    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()
        let entries = StatusMenu.entries(
            lastResult: lastResultText,
            canCheckForUpdates: canCheckForUpdates(),
        )
        actions = []
        for entry in entries {
            menu.addItem(makeItem(for: entry))
        }
    }

    @objc
    private func menuItemChosen(_ sender: NSMenuItem) {
        guard actions.indices.contains(sender.tag) else { return }
        perform(actions[sender.tag])
    }

    private var lastResultText: String? {
        runner.state.lastResult?.item.displayText
    }

    private func makeItem(for entry: MenuEntry) -> NSMenuItem {
        switch entry.kind {
        case .separator:
            return .separator()
        case .label:
            let label = NSMenuItem(title: entry.title, action: nil, keyEquivalent: "")
            label.isEnabled = false
            return label
        case .item(let action):
            let menuItem = NSMenuItem(
                title: entry.title,
                action: #selector(menuItemChosen(_:)),
                keyEquivalent: "",
            )
            menuItem.target = self
            menuItem.isEnabled = entry.isEnabled
            menuItem.tag = actions.count
            actions.append(action)
            return menuItem
        }
    }

    private func show(_ icon: StatusIcon) {
        guard let button = item.button else { return }
        let image = NSImage(
            systemSymbolName: icon.symbolName,
            accessibilityDescription: icon.accessibilityLabel,
        )
        image?.isTemplate = true
        button.image = image
        button.setAccessibilityLabel(icon.accessibilityLabel)
    }
}
