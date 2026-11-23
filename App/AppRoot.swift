import AppKit
import Core
import ModelCatalog
import Session
import UI

@MainActor
internal final class AppRoot {
    private let core: AppCore
    private let models: AppModels
    private let windows: AppWindows
    private let actions: AppActions
    private let hud: HUDPanelController
    private let status: StatusItemController
    private let updater: UpdaterController
    private let systemEvents: SystemEvents
    private let onboarding = OnboardingFlag(defaults: .standard)
    private var permissionTask: Task<Void, Never>?
    private var settingsRequests: Task<Void, Never>?
    private var warming: Task<Void, Never>?

    init() {
        let core = AppCore.make()
        let actions = AppActions()
        let models = AppModels.make(core: core, actions: actions)
        let windows = AppWindows(
            models: models.windows,
            onboardingVisibility: { core.permissions.setOnboardingVisible($0) },
        )
        let updater = UpdaterController(runner: core.runner)
        self.core = core
        self.models = models
        self.windows = windows
        self.actions = actions
        self.updater = updater
        hud = Self.makeHUD(core: core, windows: windows)
        status = Self.makeStatusItem(
            core: core,
            models: models,
            windows: windows,
            updater: updater,
        )
        systemEvents = SystemEvents(runner: core.runner, residency: core.engines.residency)
        wire(actions)
    }

    isolated deinit {
        permissionTask?.cancel()
        settingsRequests?.cancel()
        warming?.cancel()
    }

    func start() async {
        #if DEBUG
        DebugLaunch.applyAppearance()
        #endif
        hud.start()
        status.start()
        systemEvents.start()
        updater.start()
        core.router.start()
        warmUpEngines()
        watchPermissions()
        watchSettingsRequests()
        await core.runner.launch()
        await core.stores.retention.start()
        LaunchAtLogin.apply(core.preferences.read().launchAtLogin)
        await LegacyDownloadCleanup.run()
        await models.downloads.refresh()
        models.downloads.ensureDownloaded(core.engines.resolver.selectedEntries())
        #if DEBUG
        if let directory = ShotRenderer.directory {
            await ShotRenderer.render(models: models.windows, to: directory)
            NSApp.terminate(nil)
            return
        }
        #endif
        #if DEBUG
        if DebugLaunch.seedsHistory { await DebugLaunch.seed(core.stores.history) }
        if let target = DebugLaunch.target {
            DebugLaunch.present(target, on: actions, status: status)
            return
        }
        #endif
        presentOnboardingIfNeeded()
    }

    private func warmUpEngines() {
        let core = core
        warming = Task {
            await core.voice.warmUp()
            await core.engines.resolver.warmUp()
        }
    }

    func showSettings() {
        windows.showSettings(.general)
    }

    private func wire(_ actions: AppActions) {
        let windows = windows
        let onboarding = onboarding
        actions.showSettings = { windows.showSettings($0) }
        actions.showHistory = { windows.showHistory() }
        actions.finishOnboarding = {
            onboarding.isCompleted = true
            windows.closeOnboarding()
        }
    }

    private func presentOnboardingIfNeeded() {
        #if DEBUG
        if HUDShowcase.isRequested { return }
        #endif
        guard !onboarding.isCompleted else { return }
        windows.showOnboarding()
    }

    private func watchPermissions() {
        let core = core
        permissionTask = Task {
            for await status in core.permissions.status {
                core.runner.permissionChanged(status)
                if status.isAccessibilityTrusted { core.router.startTap() }
            }
        }
    }

    private func watchSettingsRequests() {
        let center = DistributedNotificationCenter.default()
        settingsRequests = Task { [weak self] in
            for await _ in center.notifications(named: SingleInstance.openSettingsNotification) {
                self?.showSettings()
            }
        }
    }
}
