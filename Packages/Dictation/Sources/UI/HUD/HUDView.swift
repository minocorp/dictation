import Core
public import SwiftUI

public struct HUDView: View {
    private static let contentFade = 0.1
    private static let presentFade = 0.15

    let model: HUDModel

    @Environment(\.colorSchemeContrast)
    private var contrast
    @Environment(\.accessibilityReduceMotion)
    private var reduceMotion
    @State
    private var isHovering = false

    public init(model: HUDModel) {
        self.model = model
    }

    private var isEditing: Bool { model.displayed.kind == .editing }
    private var openableProblem: Problem? {
        guard case .problem(let problem) = model.displayed, problem.fix != nil else { return nil }
        return problem
    }
    private var borderWidth: CGFloat {
        contrast == .increased ? HUDMetrics.contrastBorderWidth : HUDMetrics.borderWidth
    }
    private var groupsChildren: AccessibilityChildBehavior {
        switch model.displayed.kind {
        case .handsFree, .canceled: .contain
        case .hidden, .listening, .editing, .processing, .copied, .saved, .noSpeech, .problem:
            .combine
        }
    }

    private var statusLabel: String {
        HUDAnnouncement.announcement(for: model.displayed)?.text
            ?? UIString.string(UIString.hudStatusLabel)
    }

    public var body: some View {
        HStack(spacing: HUDMetrics.spacing) {
            HUDStateContent(model: model, state: model.displayed)
        }
        .padding(.horizontal, HUDMetrics.horizontalPadding)
        .frame(minWidth: HUDMetrics.minimumWidth, minHeight: HUDMetrics.height)
        .frame(height: HUDMetrics.height)
        .background { tint }
        .overlay { border }
        .clipShape(Capsule())
        .contentShape(Capsule())
        .fixedSize()
        .onGeometryChange(for: CGSize.self, of: \.size) { model.contentSize = $0 }
        .scaleEffect(model.isPresented || reduceMotion ? 1 : HUDMetrics.presentedScale)
        .opacity(model.isPresented ? 1 : 0)
        .animation(
            reduceMotion ? nil : .easeOut(duration: Self.presentFade),
            value: model.isPresented,
        )
        .animation(.easeInOut(duration: Self.contentFade), value: model.displayed.kind)
        .onHover { isHovering = $0 }
        .onTapGesture { openProblemFix() }
        .onChange(of: reduceMotion, initial: true) { _, value in model.reducesMotion = value }
        .accessibilityElement(children: groupsChildren)
        .accessibilityLabel(Text(statusLabel))
        .accessibilityAddTraits(openableProblem == nil ? [] : .isButton)
    }

    @ViewBuilder
    private var tint: some View {
        if isEditing {
            Capsule().fill(Color.accentColor.opacity(HUDMetrics.editingTintOpacity))
        } else if openableProblem != nil {
            Capsule().fill(Color.primary.opacity(isHovering ? 0.10 : 0))
        }
    }

    @ViewBuilder
    private var border: some View {
        if isEditing {
            Capsule().strokeBorder(Color.accentColor, lineWidth: borderWidth)
        }
    }

    private func openProblemFix() {
        guard let openableProblem else { return }
        model.openFix(for: openableProblem)
    }
}
