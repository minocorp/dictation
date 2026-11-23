import Foundation
import Session
import Sparkle

@MainActor
internal final class UpdaterController {
    private let delegate: IdleUpdateDelegate
    private let controller: SPUStandardUpdaterController
    private let isConfigured: Bool

    init(runner: SessionRunner) {
        delegate = IdleUpdateDelegate(runner: runner)
        controller = SPUStandardUpdaterController(
            startingUpdater: false,
            updaterDelegate: delegate,
            userDriverDelegate: nil,
        )
        let key = Bundle.main.object(forInfoDictionaryKey: "SUPublicEDKey") as? String
        isConfigured = key?.isEmpty == false
    }

    var canCheckForUpdates: Bool {
        isConfigured && controller.updater.canCheckForUpdates
    }

    func start() {
        guard isConfigured else {
            AppLog.info("updater disabled: SUPublicEDKey is empty")
            return
        }
        controller.startUpdater()
    }

    func checkForUpdates() {
        guard isConfigured else { return }
        controller.checkForUpdates(nil)
    }
}
