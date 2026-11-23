import AppKit
import Core
import Foundation
import Hotkeys
import ModelCatalog
import UI

@MainActor
internal struct AppModels {
    let windows: WindowModels
    let downloads: ModelDownloads
    let settings: SettingsModel

    static func make(core: AppCore, actions: AppActions) -> AppModels {
        let settings = makeSettings(core: core, actions: actions)
        let downloads = makeDownloads(core: core)
        let library = core.engines.library
        let dictionary = DictionaryModel(store: core.stores.words)
        let modelsModel = ModelsModel(
            settings: settings,
            downloads: downloads,
            library: library,
            actions: makeModelActions(core: core),
        )
        let windows = WindowModels(
            settings: SettingsWindowModel(
                settings: settings,
                dictionary: dictionary,
                models: modelsModel,
                about: makeAbout(core: core),
            ),
            history: makeHistory(core: core, dictionary: dictionary),
            onboarding: OnboardingModel(
                settings: settings,
                downloads: downloads,
                environment: makeOnboarding(core: core, actions: actions),
            ),
        )
        return AppModels(windows: windows, downloads: downloads, settings: settings)
    }

    private static func makeSettings(core: AppCore, actions: AppActions) -> SettingsModel {
        SettingsModel(
            preferences: core.preferences.read(),
            environment: SettingsEnvironment(
                apply: { preferences in
                    let retentionChanged =
                        core.preferences.read().historyRetention != preferences.historyRetention
                    core.preferences.write(preferences)
                    core.runner.preferencesChanged()
                    if retentionChanged { Task { await core.stores.retention.retentionChanged() } }
                    core.router.preferencesChanged()
                    LaunchAtLogin.apply(preferences.launchAtLogin)
                },
                microphones: { InputDevices.options() },
                languages: { await SupportedLanguages.load() },
                captureKeys: { core.router.captureKeys() },
                globeAdvice: { GlobeAdvice(GlobeSettingReader().read()) },
                openKeyboardSettings: { SystemSettingsLinks.openKeyboard() },
                clearHistory: {
                    do {
                        try await core.stores.history.deleteAll()
                    } catch {
                        AppLog.failure("clear history", error)
                    }
                },
            ),
        )
    }

    private static func makeDownloads(core: AppCore) -> ModelDownloads {
        ModelDownloads(
            library: core.engines.library,
            actions: makeModelActions(core: core),
            didBecomeReady: { stage in
                await core.runner.modelBecameReady(stage)
                await core.engines.resolver.warmUp()
            },
        )
    }

    private static func makeModelActions(core: AppCore) -> ModelActions {
        let library = core.engines.library
        let stores = core.stores
        return ModelActions(
            downloadAllowingConstrained: { library.downloadAllowingConstrainedNetwork($0) },
            cancelDownload: { library.cancelDownload(of: $0) },
            delete: { (entry) throws(ModelError) in try library.delete(entry) },
            deleteEverything: {
                await DataEraser.eraseAll(library: library, stores: stores)
            },
        )
    }

    private static func makeHistory(core: AppCore, dictionary: DictionaryModel) -> HistoryModel {
        let history = core.stores.history
        return HistoryModel(
            store: history,
            dictionary: dictionary,
            actions: HistoryActions(
                observe: { history.history(matching: $0, limit: 200) },
                copy: { text in
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(text, forType: .string)
                },
                retry: { await core.runner.retry($0) },
            ),
            calendar: .current,
        )
    }

    private static func makeAbout(core: AppCore) -> AboutModel {
        let version =
            Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""
        let exporter = core.diagnostics.makeExporter(version: version)
        let library = core.engines.library
        return AboutModel(
            version: version,
            prepare: { () async throws(DiagnosticsError) -> DiagnosticsPackage in
                let installed = await DataEraser.installedEntries(library: library)
                let bundle = try exporter.makeBundle(installedModels: installed)
                return DiagnosticsPackage(
                    fileNames: bundle.fileNames,
                    write: { (destination) throws(DiagnosticsError) in
                        try bundle.write(to: destination)
                    },
                )
            },
            chooseDestination: { DiagnosticsSavePanel.chooseDestination() },
            modelEntries: {
                ModelStage.allCases.flatMap { library.entries(stage: $0) }
            },
        )
    }

    private static func makeOnboarding(core: AppCore, actions: AppActions) -> OnboardingEnvironment
    {
        OnboardingEnvironment(
            permissions: core.permissions,
            levels: { MicrophoneLevelProbe.levels() },
            isBluetoothInput: { InputDevices.isDefaultInputBluetooth() },
            recommendedModels: { core.engines.resolver.selectedEntries() },
            finish: { actions.finishOnboarding() },
        )
    }
}
