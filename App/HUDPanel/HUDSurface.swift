import AppKit

@MainActor
internal final class HUDSurface: NSView {
    private static let cornerRadius: CGFloat = 18

    private let glass = NSGlassEffectView()
    private let solid = NSView()
    private let content: NSView

    init(content: NSView) {
        self.content = content
        super.init(frame: .zero)
        wantsLayer = true
        glass.cornerRadius = Self.cornerRadius
        solid.wantsLayer = true
        solid.layer?.cornerRadius = Self.cornerRadius
        solid.layer?.cornerCurve = .continuous
        solid.layer?.borderWidth = 1
        solid.isHidden = true
        for view in [glass, solid] {
            view.frame = bounds
            view.autoresizingMask = [.width, .height]
            addSubview(view)
        }
        content.autoresizingMask = [.width, .height]
        embedInGlass()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("HUDSurface is created in code")
    }

    func showsOpaqueFill(_ isOpaque: Bool) {
        glass.isHidden = isOpaque
        solid.isHidden = !isOpaque
        if isOpaque { embedInSolid() } else { embedInGlass() }
        refreshSolidColors()
    }

    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        refreshSolidColors()
    }

    private func embedInGlass() {
        guard glass.contentView !== content else { return }
        content.removeFromSuperview()
        content.frame = glass.bounds
        glass.contentView = content
    }

    private func embedInSolid() {
        guard content.superview !== solid else { return }
        glass.contentView = nil
        content.frame = solid.bounds
        solid.addSubview(content)
    }

    private func refreshSolidColors() {
        effectiveAppearance.performAsCurrentDrawingAppearance {
            solid.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
            solid.layer?.borderColor = NSColor.labelColor.cgColor
        }
    }
}
