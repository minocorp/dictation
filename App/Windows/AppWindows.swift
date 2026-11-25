import AppKit
import SwiftUI
import UI

@MainActor
internal final class AppWindows {
    private static let settingsSize = NSSize(width: 720, height: 500)
    private static let historySize = NSSize(width: 640, height: 520)

    private let models: WindowModels
    private let onboardingVisibility: @MainActor (Bool) -> Void
    private var settings: NSWindow?
    private var history: NSWindow?
    private var onboarding: NSWindow?
    private var closeObserver: (any NSObjectProtocol)?

    init(models: WindowModels, onboardingVisibility: @escaping @MainActor (Bool) -> Void) {
        self.models = models
        self.onboardingVisibility = onboardingVisibility
    }

    isolated deinit {
        if let closeObserver { NotificationCenter.default.removeObserver(closeObserver) }
    }

    func showSettings(_ destination: SettingsPane) {
        models.settings.show(destination)
        let window =
            settings
            ?? makeWindow(
                title: WindowTitles.settings,
                root: SettingsView(model: models.settings),
                style: [.titled, .closable, .miniaturizable, .resizable],
                size: Self.settingsSize,
            )
        settings = window
        present(window)
    }

    func showHistory() {
        let window =
            history
            ?? makeWindow(
                title: WindowTitles.history,
                root: HistoryView(model: models.history),
                style: [.titled, .closable, .miniaturizable, .resizable],
                size: Self.historySize,
            )
        history = window
        present(window)
    }

    func showOnboarding() {
        let window =
            onboarding
            ?? makeWindow(
                title: WindowTitles.onboarding,
                root: OnboardingView(model: models.onboarding),
                style: [.titled, .closable],
                size: nil,
            )
        if onboarding == nil { observeClose(of: window) }
        onboarding = window
        onboardingVisibility(true)
        present(window)
    }

    func closeOnboarding() {
        onboarding?.close()
    }

    private func observeClose(of window: NSWindow) {
        closeObserver = NotificationCenter.default.addObserver(
            forName: NSWindow.willCloseNotification,
            object: window,
            queue: .main,
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.onboardingVisibility(false) }
        }
    }

    private func present(_ window: NSWindow) {
        NSApp.activate()
        window.makeKeyAndOrderFront(nil)
    }

    private func makeWindow(
        title: String,
        root: some View,
        style: NSWindow.StyleMask,
        size: NSSize?,
    ) -> NSWindow {
        let window = NSWindow(contentViewController: NSHostingController(rootView: root))
        window.styleMask = style
        window.title = title
        window.isReleasedWhenClosed = false
        if let size { window.setContentSize(size) }
        window.center()
        return window
    }
}
