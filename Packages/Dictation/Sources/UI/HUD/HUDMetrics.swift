import SwiftUI

internal enum HUDMetrics {
    static let height: CGFloat = 36
    static let minimumWidth: CGFloat = 120
    static let horizontalPadding: CGFloat = 14
    static let spacing: CGFloat = 10
    static let controlSize: CGFloat = 24
    static let barWidth: CGFloat = 2.5
    static let barSpacing: CGFloat = 2.5
    static let minimumBarHeight: CGFloat = 3
    static let maximumBarHeight: CGFloat = 20
    static let barEnvelope: [Float] = [0.25, 0.5, 0.85, 0.6, 1, 0.7, 0.4, 0.65, 0.3]
    static let editingTintOpacity = 0.22
    static let keycapOpacityLight = 0.13
    static let keycapOpacityDark = 0.24
    static let borderWidth: CGFloat = 1
    static let contrastBorderWidth: CGFloat = 1.5
    static let presentedScale: CGFloat = 0.96
    static let pasteKeycap = "⌘V"

    static let text = Font.system(size: 13)
    static let emphasizedText = Font.system(size: 13, weight: .semibold)
    static let keycap = Font.system(size: 12)
    static let timer = Font.system(size: 12, design: .monospaced)
    static let countdown = Font.system(size: 12, weight: .semibold, design: .monospaced)
    static let controlGlyph = Font.system(size: 10, weight: .bold)
    static let chevron = Font.system(size: 10, weight: .semibold)
    static let problemGlyph = Font.system(size: 11, weight: .bold)

    static let clipboardSymbol = "list.clipboard"
    static let savedSymbol = "tray"
    static let restoreSymbol = "arrow.counterclockwise"
    static let chevronSymbol = "chevron.right"
}
