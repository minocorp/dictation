public import Core
import Foundation
public import Observation

@MainActor
@Observable
public final class OnboardingModel {
    public private(set) var permissions = PermissionStatus(
        microphone: .notDetermined,
        isAccessibilityTrusted: false,
    )
    public private(set) var level: Float = 0

    public let keyRecorder: KeyRecorderModel
    public let settings: SettingsModel

    @ObservationIgnored
    private let downloads: ModelDownloads
    @ObservationIgnored
    private let environment: OnboardingEnvironment
    @ObservationIgnored
    private var meter = LevelMeter()
    @ObservationIgnored
    private var lastLevelUpdate: ContinuousClock.Instant?

    public init(
        settings: SettingsModel,
        downloads: ModelDownloads,
        environment: OnboardingEnvironment,
    ) {
        self.settings = settings
        self.downloads = downloads
        self.environment = environment
        keyRecorder = settings.makeRecorder(.dictateKey)
    }

    var isMicrophoneGranted: Bool { permissions.microphone == .granted }
    var isMicrophoneDenied: Bool { permissions.microphone == .denied }
    var isKeyConfirmed: Bool { keyRecorder.confirmations > 0 }
    var showsBluetoothNote: Bool { environment.isBluetoothInput() }
    var canFinish: Bool {
        isMicrophoneGranted && permissions.isAccessibilityTrusted && isKeyConfirmed
    }

    var activeStep: OnboardingStep {
        if !isMicrophoneGranted { return .microphone }
        if !permissions.isAccessibilityTrusted { return .accessibility }
        if !isKeyConfirmed { return .key }
        return .tryIt
    }

    var downloadNote: ModelDownloadNote {
        let entries = environment.recommendedModels().filter(\.isDownloadable)
        guard !entries.isEmpty else { return .none }
        let states = entries.map { downloads.state(of: $0) }
        let total = entries.reduce(0) { $0 + $1.downloadBytes }
        if let error = states.lazy.compactMap(failure(of:)).first {
            return .failed(error)
        }
        if states.contains(.waitingForApproval) { return .waitingForApproval }
        if states.allSatisfy({ $0 == .ready }) { return .ready }
        let progress =
            downloads.progress(of: entries)
            ?? DownloadProgress(receivedBytes: 0, totalBytes: total)
        return .downloading(progress, totalBytes: total)
    }

    public func watchPermissions() async {
        for await status in environment.permissions.status {
            permissions = status
        }
    }

    public func watchLevels() async {
        guard isMicrophoneGranted else {
            resetMeter()
            return
        }
        for await value in environment.levels() {
            advanceMeter(toward: value)
        }
    }

    func allowMicrophone() async {
        await environment.permissions.request(.microphone)
    }

    func openSettings(for permission: Permission) async {
        await environment.permissions.openSettings(for: permission)
    }

    func retryDownloads() {
        for entry in environment.recommendedModels() where entry.isDownloadable {
            if case .failed = downloads.state(of: entry) { downloads.download(entry) }
        }
    }

    func allowDownloads() {
        for entry in environment.recommendedModels() where entry.isDownloadable {
            downloads.downloadAllowingConstrained(entry)
        }
    }

    func finish() {
        environment.finish()
    }

    private func failure(of state: ModelState) -> ModelError? {
        guard case .failed(let error) = state else { return nil }
        return error
    }

    private func advanceMeter(toward value: Float) {
        let clock = ContinuousClock()
        let now = clock.now
        let elapsed = lastLevelUpdate.map { $0.duration(to: now) / .seconds(1) } ?? 1.0 / 30
        lastLevelUpdate = now
        meter.advance(toward: value, elapsed: elapsed, smoothing: true)
        level = meter.level
    }

    private func resetMeter() {
        meter.reset()
        lastLevelUpdate = nil
        level = 0
    }
}
