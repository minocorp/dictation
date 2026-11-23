import AppKit
import Core
import SwiftUI
import UI

@MainActor
internal final class HUDPanelController {
    private static let fadeDuration = Duration.milliseconds(150)
    private static let resizeDuration: TimeInterval = 0.2

    private let model: HUDModel
    private let panel = HUDPanel()
    private let hosting: NSHostingView<HUDView>
    private let surface: HUDSurface
    private var display: DisplayGeometry?
    private var watching: Task<Void, Never>?
    private var hiding: Task<Void, Never>?
    private var observer: Task<Void, Never>?
    private var stateWatch: Task<Void, Never>?
    private var levelWatch: Task<Void, Never>?

    init(model: HUDModel) {
        self.model = model
        hosting = NSHostingView(rootView: HUDView(model: model))
        hosting.sizingOptions = [.intrinsicContentSize]
        hosting.layer?.backgroundColor = .clear
        surface = HUDSurface(content: hosting)
        panel.contentView = surface
        #if DEBUG
        if CommandLine.arguments.contains("--hud-light") {
            panel.appearance = NSAppearance(named: .aqua)
        }
        #endif
    }

    isolated deinit {
        watching?.cancel()
        hiding?.cancel()
        observer?.cancel()
        stateWatch?.cancel()
        levelWatch?.cancel()
    }

    func start() {
        refreshAccessibility()
        let model = model
        stateWatch = Task { await model.watchState() }
        levelWatch = Task { await model.watchLevels() }
        let center = NSWorkspace.shared.notificationCenter
        observer = Task { [weak self] in
            for await _ in center.notifications(
                named: NSWorkspace.accessibilityDisplayOptionsDidChangeNotification
            ) {
                self?.refreshAccessibility()
            }
        }
        watching = Task { [weak self] in
            guard let model = self?.model else { return }
            for await (state, size) in Observations({ (model.state, model.contentSize) }) {
                self?.update(state: state, size: size)
            }
        }
    }

    private func refreshAccessibility() {
        let workspace = NSWorkspace.shared
        surface.showsOpaqueFill(
            workspace.accessibilityDisplayShouldIncreaseContrast
                || workspace.accessibilityDisplayShouldReduceTransparency
        )
    }

    private func update(state: HUDState, size: CGSize) {
        panel.ignoresMouseEvents = !model.acceptsMouse
        guard state != .hidden else {
            scheduleHide()
            return
        }
        hiding?.cancel()
        let contentSize = size == .zero ? hosting.fittingSize : size
        let wasVisible = panel.isVisible
        if !wasVisible { display = chooseDisplay() }
        guard let display else { return }
        let frame = HUDPlacement.frame(size: contentSize, on: display)
        if wasVisible, !model.reducesMotion {
            NSAnimationContext.runAnimationGroup { context in
                context.duration = Self.resizeDuration
                panel.animator().setFrame(frame, display: true)
            }
        } else {
            panel.setFrame(frame, display: true)
        }
        if !wasVisible { panel.orderFrontRegardless() }
    }

    private func scheduleHide() {
        hiding?.cancel()
        hiding = Task { [weak self] in
            do {
                try await ContinuousClock().sleep(for: Self.fadeDuration)
            } catch {
                return
            }
            self?.panel.orderOut(nil)
        }
    }

    private func chooseDisplay() -> DisplayGeometry? {
        let displays = NSScreen.screens.map {
            DisplayGeometry(frame: $0.frame, visibleFrame: $0.visibleFrame)
        }
        return HUDPlacement.display(for: FocusedWindowLocator.frame(), among: displays)
    }
}
