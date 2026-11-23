import Core
import SwiftUI

internal struct HUDStateContent: View {
    let model: HUDModel
    let state: HUDState

    @Environment(\.colorSchemeContrast)
    private var contrast
    @Environment(\.accessibilityReduceMotion)
    private var reduceMotion

    private var secondary: Color { contrast == .increased ? .primary : .secondary }

    var body: some View {
        switch state {
        case .hidden:
            EmptyView()
        case .listening:
            HUDLevelBars(heights: model.barHeights, style: .primary)
        case .handsFree(let elapsed, let countdown):
            HUDHandsFreeContent(model: model, elapsed: elapsed, countdown: countdown)
        case .editing:
            HUDLevelBars(heights: model.barHeights, style: Color.accentColor)
            Text(UIString.hudEditing)
                .font(HUDMetrics.emphasizedText)
        case .processing:
            HUDSpinner(reducesMotion: reduceMotion)
            Text(UIString.hudProcessing)
                .font(HUDMetrics.text)
        case .copied:
            Image(systemName: HUDMetrics.clipboardSymbol)
                .font(HUDMetrics.text)
            Text(UIString.hudCopied)
                .font(HUDMetrics.text)
            HUDKeycap(text: HUDMetrics.pasteKeycap)
        case .canceled:
            Text(UIString.hudCanceled)
                .font(HUDMetrics.text)
            HUDRestoreButton(action: model.restore)
        case .saved:
            Image(systemName: HUDMetrics.savedSymbol)
                .font(HUDMetrics.text)
            Text(UIString.hudSaved)
                .font(HUDMetrics.text)
        case .noSpeech:
            Text(UIString.hudNoSpeech)
                .font(HUDMetrics.text)
                .foregroundStyle(secondary)
        case .problem(let problem):
            HUDProblemGlyph()
            Text(problem.message)
                .font(HUDMetrics.text)
            if problem.fix != nil {
                Image(systemName: HUDMetrics.chevronSymbol)
                    .font(HUDMetrics.chevron)
                    .foregroundStyle(secondary)
            }
        }
    }
}
