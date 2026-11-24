#if DEBUG
import AppKit
import Core
import SwiftUI
import UI

@MainActor
internal enum ShotRenderer {
    private static let prefix = "--render-shots="

    static var directory: URL? {
        CommandLine.arguments.first { $0.hasPrefix(prefix) }
            .map { URL(filePath: String($0.dropFirst(prefix.count))) }
    }

    static func render(models: WindowModels, to directory: URL) async {
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        await renderHUDStates(to: directory)
        await write(OnboardingView(model: models.onboarding), "onboarding", directory)
        for pane in [SettingsPane.general, .models, .about] {
            models.settings.show(pane)
            await write(SettingsView(model: models.settings), "settings-\(pane)", directory)
        }
        await write(HistoryView(model: models.history), "history", directory)
    }

    private static func renderHUDStates(to directory: URL) async {
        let states: [(String, HUDState)] = [
            ("listening", .listening),
            ("handsfree", .handsFree(elapsed: .seconds(42), countdown: nil)),
            ("countdown", .handsFree(elapsed: .seconds(111), countdown: .seconds(9))),
            ("editing", .editing), ("processing", .processing), ("copied", .copied),
            ("canceled", .canceled), ("saved", .saved), ("nospeech", .noSpeech),
            ("problem", .problem(.microphoneDenied)), ("password", .problem(.passwordField)),
        ]
        for (name, state) in states {
            let model = HUDModel(
                state: { state },
                levels: HUDShowcase.levels(),
                actions: HUDActions(perform: { _ in }, openFix: { _ in }, announce: { _ in }),
            )
            let watcher = Task { await model.watchState() }
            try? await ContinuousClock().sleep(for: .milliseconds(300))
            await write(
                HUDView(model: model).padding(40).background(Color.gray.opacity(0.35)),
                "hud-\(name)",
                directory,
            )
            watcher.cancel()
        }
    }

    private static func write(_ view: some View, _ name: String, _ directory: URL) async {
        let host = NSHostingView(rootView: view)
        let fitting = host.fittingSize
        let size =
            fitting.width < 100 || name.hasPrefix("settings") || name == "history"
            ? CGSize(width: name == "history" ? 640 : 720, height: 500) : fitting
        let window = NSWindow(
            contentRect: CGRect(origin: .zero, size: size),
            styleMask: [.titled, .resizable],
            backing: .buffered,
            defer: false,
        )
        window.contentView = host
        window.setContentSize(size)
        window.orderFrontRegardless()
        try? await ContinuousClock().sleep(for: .milliseconds(900))
        host.layoutSubtreeIfNeeded()
        guard let rep = host.bitmapImageRepForCachingDisplay(in: host.bounds) else { return }
        host.cacheDisplay(in: host.bounds, to: rep)
        try? rep.representation(using: .png, properties: [:])?
            .write(to: directory.appending(path: "\(name).png"))
        window.orderOut(nil)
    }
}
#endif
