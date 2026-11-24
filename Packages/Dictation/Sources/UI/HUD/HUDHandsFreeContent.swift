import Core
import SwiftUI

internal struct HUDHandsFreeContent: View {
    private static let clockStyle = Duration.TimeFormatStyle(
        pattern: .minuteSecond(padMinuteToLength: 1)
    )

    let model: HUDModel
    let elapsed: Duration
    let countdown: Duration?

    var body: some View {
        HUDLevelBars(heights: model.barHeights, style: .primary)
        if let countdown {
            Text(countdown, format: Self.clockStyle)
                .font(HUDMetrics.countdown)
                .monospacedDigit()
                .foregroundStyle(.primary)
        } else {
            Text(elapsed, format: Self.clockStyle)
                .font(HUDMetrics.timer)
                .monospacedDigit()
                .foregroundStyle(.secondary)
        }
        HUDControlButton(systemImage: "stop.fill", label: UIString.hudStop, action: model.stop)
        HUDControlButton(systemImage: "xmark", label: UIString.commonCancel, action: model.cancel)
    }
}
