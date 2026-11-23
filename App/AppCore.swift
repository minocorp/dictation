import Capture
import Cleanup
import Context
import Core
import Diagnostics
import Foundation
import Hotkeys
import Insertion
import Learning
import Pasteboard
import Permissions
import Recognition
import Session

@MainActor
internal struct AppCore {
    let paths: AppPaths
    let preferences: PreferencesStore
    let stores: AppStores
    let engines: AppEngines
    let audio: DeviceAudioSource
    let permissions: SystemPermissionMonitor
    let voice: SileroVoiceActivity
    let runner: SessionRunner
    let router: KeyEventRouter
    let diagnostics: DiagnosticsKit

    static func make() -> AppCore {
        let paths = AppPaths.make()
        paths.prepare()
        let preferences = PreferencesStore(fallback: makeDefaultPreferences())
        let stores = AppStores.make(paths: paths, preferences: preferences)
        let engines = AppEngines.make(paths: paths, preferences: preferences)
        let audio = DeviceAudioSource(audioDirectory: paths.audio)
        let diagnostics = DiagnosticsKit.make(paths: paths)
        let keys = EventTapKeySource()
        let voice = SileroVoiceActivity()
        let runner = makeRunner(
            keys: keys,
            audio: audio,
            voice: voice,
            services: RunnerServices(
                stores: stores,
                engines: engines,
                preferences: preferences,
                diagnostics: diagnostics,
            ),
        )
        return AppCore(
            paths: paths,
            preferences: preferences,
            stores: stores,
            engines: engines,
            audio: audio,
            permissions: SystemPermissionMonitor(),
            voice: voice,
            runner: runner,
            router: KeyEventRouter(keys: keys, runner: runner, preferences: preferences),
            diagnostics: diagnostics,
        )
    }

    private static func makeDefaultPreferences() -> Preferences {
        .makeDefault(
            globeSwitchesInputSource: GlobeSettingReader().read().changesInputSource,
            preferredLanguages: Locale.preferredLanguages.map { Locale(identifier: $0) },
        )
    }

    private static func makeRunner(
        keys: EventTapKeySource,
        audio: DeviceAudioSource,
        voice: SileroVoiceActivity,
        services: RunnerServices,
    ) -> SessionRunner {
        let transaction = ClipboardTransaction()
        let focus = AccessibilityFocusReader(transaction: transaction)
        let clipboard = PasteboardClipboardWriter(transaction: transaction)
        return SessionRunner(
            inputs: SessionInputs(
                keys: keys,
                audio: audio,
                voice: voice,
                files: CAFAudioFileSegmenter(voice: voice),
            ),
            engines: makeEngines(services),
            outputs: SessionOutputs(
                focus: focus,
                inserter: makeInserter(services, transaction, focus, clipboard),
                clipboard: clipboard,
                sounds: AppSoundPlayer(),
            ),
            environment: SessionEnvironment(
                history: services.stores.history,
                preferences: { [preferences = services.preferences] in preferences.read() },
                clock: ContinuousClock(),
            ),
        )
    }

    private static func makeEngines(_ services: RunnerServices) -> SessionEngines {
        let resolver = services.engines.resolver
        let preferences = services.preferences
        let words = services.stores.words
        return SessionEngines(
            speech: { await resolver.speech() },
            preheat: {
                async let dictionary = words.all()
                await resolver.speech().preheat()
                if preferences.read().cleanup { await resolver.cleanup().preheat() }
                _ = try? await dictionary
            },
            cleanup: EngineCleanupPipeline(
                resolver: resolver,
                preferences: preferences,
                budget: .recommended(for: RAMTier(ramGB: MachineMemory.gigabytes)),
            ),
            words: words,
            learning: LearningBridge(
                learner: CorrectionLearner(words: services.stores.words),
                isEnabled: { preferences.read().learning },
            ),
        )
    }

    private static func makeInserter(
        _ services: RunnerServices,
        _ transaction: ClipboardTransaction,
        _ focus: AccessibilityFocusReader,
        _ clipboard: PasteboardClipboardWriter,
    ) -> RecordingTextInserter {
        RecordingTextInserter(
            base: PasteTextInserter(
                transaction: transaction,
                focusReader: focus,
                clipboard: clipboard,
            ),
            log: services.diagnostics.insertions,
        )
    }
}
