import Core
import CoreTesting
import Testing
@testable import UI

@MainActor
internal struct OnboardingModelTests {
    private let monitor = FakePermissionMonitor()
    private let speech = UIFixtures.entry(id: "speech-a", stage: .speech, bytes: 1_000)

    private func makeModel(library: FakeModelLibrary? = nil) -> (OnboardingModel, ModelDownloads) {
        let library =
            library
            ?? FakeModelLibrary(
                recommended: (speech: speech, cleanup: .appleFoundationModels),
                entries: [speech],
            )
        let settings = makeSettings()
        let downloads = ModelDownloads(
            library: library,
            actions: ModelActions(
                downloadAllowingConstrained: { _ in AsyncStream { $0.finish() } },
                cancelDownload: { _ in },
                delete: { _ in },
                deleteEverything: {},
            ),
            didBecomeReady: { _ in },
        )
        let speech = speech
        let model = OnboardingModel(
            settings: settings,
            downloads: downloads,
            environment: OnboardingEnvironment(
                permissions: monitor,
                levels: { AsyncStream { $0.finish() } },
                isBluetoothInput: { false },
                recommendedModels: { [speech] },
                finish: {},
            ),
        )
        Task { await model.watchPermissions() }
        return (model, downloads)
    }

    private func makeSettings() -> SettingsModel {
        SettingsModel(
            preferences: .makeDefault(globeSwitchesInputSource: false, preferredLanguages: []),
            environment: SettingsEnvironment(
                apply: { _ in },
                microphones: { [] },
                languages: { [] },
                captureKeys: { AsyncStream { $0.finish() } },
                globeAdvice: { .none },
                openKeyboardSettings: {},
                clearHistory: {},
            ),
        )
    }

    private func waitForStatus(_ model: OnboardingModel, _ status: PermissionStatus) async {
        monitor.emit(status)
        for _ in 0..<10_000 where model.permissions != status { await Task.yield() }
    }

    @Test
    func startsOnTheMicrophoneStep() {
        #expect(makeModel().0.activeStep == .microphone)
    }

    @Test
    func advancesAsPermissionsAreGranted() async {
        let (model, _) = makeModel()
        await waitForStatus(
            model,
            PermissionStatus(microphone: .granted, isAccessibilityTrusted: false),
        )
        #expect(model.activeStep == .accessibility)
        await waitForStatus(
            model,
            PermissionStatus(microphone: .granted, isAccessibilityTrusted: true),
        )
        #expect(model.activeStep == .key)
        #expect(!model.canFinish)
    }

    @Test
    func confirmingTheKeyUnlocksTryItAndFinish() async {
        let (model, _) = makeModel()
        await waitForStatus(
            model,
            PermissionStatus(microphone: .granted, isAccessibilityTrusted: true),
        )
        #expect(model.keyRecorder.receive(UIFixtures.event(code: 63, modifiers: [.function])))
        #expect(model.activeStep == .tryIt)
        #expect(model.canFinish)
    }

    @Test
    func deniedMicrophoneOffersSettings() async {
        let (model, _) = makeModel()
        await waitForStatus(
            model,
            PermissionStatus(microphone: .denied, isAccessibilityTrusted: false),
        )
        #expect(model.isMicrophoneDenied)
        await model.openSettings(for: .microphone)
        #expect(monitor.openedSettings == [.microphone])
    }

    @Test
    func microphoneRequestGoesToTheMonitor() async {
        await makeModel().0.allowMicrophone()
        #expect(monitor.requests == [.microphone])
    }

    @Test
    func downloadNoteFollowsModelState() async {
        let library = FakeModelLibrary(
            recommended: (speech: speech, cleanup: .appleFoundationModels),
            entries: [speech],
        )
        let (model, downloads) = makeModel(library: library)
        library.setState(.waitingForApproval, of: speech)
        library.setDownloadScript([.waitingForApproval], for: speech)
        downloads.download(speech)
        for _ in 0..<1_000 where model.downloadNote != .waitingForApproval { await Task.yield() }
        #expect(model.downloadNote == .waitingForApproval)
    }

    @Test
    func downloadNoteSurfacesFailure() async {
        let library = FakeModelLibrary(
            recommended: (speech: speech, cleanup: .appleFoundationModels),
            entries: [speech],
        )
        let (model, downloads) = makeModel(library: library)
        library.setDownloadScript([.failed(.hashMismatch(path: "weights"))], for: speech)
        downloads.download(speech)
        let expected = ModelDownloadNote.failed(.hashMismatch(path: "weights"))
        for _ in 0..<1_000 where model.downloadNote != expected { await Task.yield() }
        #expect(model.downloadNote == expected)
    }
}
