import SwiftUI

internal struct HUDSpinner: View {
    private static let diameter: CGFloat = 16
    private static let lineWidth: CGFloat = 1.75
    private static let turnDuration = 0.9

    let reducesMotion: Bool

    @State
    private var isTurning = false

    var body: some View {
        if reducesMotion {
            Image(systemName: "hourglass")
                .font(HUDMetrics.text)
                .foregroundStyle(.secondary)
        } else {
            Circle()
                .trim(from: 0, to: 0.75)
                .stroke(
                    .secondary,
                    style: StrokeStyle(lineWidth: Self.lineWidth, lineCap: .round),
                )
                .frame(width: Self.diameter, height: Self.diameter)
                .rotationEffect(.degrees(isTurning ? 360 : 0))
                .animation(
                    .linear(duration: Self.turnDuration).repeatForever(autoreverses: false),
                    value: isTurning,
                )
                .onAppear { isTurning = true }
        }
    }
}
