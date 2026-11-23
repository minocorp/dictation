import AppKit
import Core
import Session
import UI

extension AppRoot {
    static func makeHUD(core: AppCore, windows: AppWindows) -> HUDPanelController {
        let runner = core.runner
        let permissions = core.permissions
        let actions = HUDActions(
            perform: { runner.perform($0) },
            openFix: { fix in
                switch fix {
                case .openPermissionSettings(let permission):
                    Task { await permissions.openSettings(for: permission) }
                case .openModels:
                    windows.showSettings(.models)
                }
            },
            announce: { text in
                NSAccessibility.post(
                    element: NSApp as Any,
                    notification: .announcementRequested,
                    userInfo: [
                        .announcement: text,
                        .priority: NSAccessibilityPriorityLevel.medium.rawValue,
                    ],
                )
            },
        )
        return HUDPanelController(model: makeHUDModel(core: core, actions: actions))
    }

    static func makeStatusItem(
        core: AppCore,
        models: AppModels,
        windows: AppWindows,
        updater: UpdaterController,
    ) -> StatusItemController {
        let runner = core.runner
        return StatusItemController(
            runner: runner,
            downloads: models.downloads,
            canCheckForUpdates: { updater.canCheckForUpdates },
            perform: { action in
                switch action {
                case .copyLastResult: copyLastResult(runner)
                case .pasteLast: runner.perform(.pasteLast)
                case .showHistory: windows.showHistory()
                case .showSettings: windows.showSettings(.general)
                case .showAbout: windows.showSettings(.about)
                case .checkForUpdates: updater.checkForUpdates()
                case .quit: NSApp.terminate(nil)
                }
            },
        )
    }

    private static func makeHUDModel(core: AppCore, actions: HUDActions) -> HUDModel {
        let runner = core.runner
        #if DEBUG
        if HUDShowcase.isRequested {
            let showcase = HUDShowcase()
            showcase.start()
            return HUDModel(
                state: { showcase.state },
                levels: HUDShowcase.levels(),
                actions: actions,
            )
        }
        #endif
        return HUDModel(state: { runner.state.hud }, levels: core.audio.levels, actions: actions)
    }

    private static func copyLastResult(_ runner: SessionRunner) {
        guard let item = runner.state.lastResult?.item else { return }
        let text = item.finalText.isEmpty ? item.rawText : item.finalText
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
    }
}
