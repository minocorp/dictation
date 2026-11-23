import ApplicationServices
import Core

internal struct LiveTapProbe: TapProbe {
    let context: TapContext

    func read() -> TapHealth {
        let isTrusted = AXIsProcessTrusted()
        var isEnabled = context.areTapsEnabled()
        if !isEnabled, isTrusted {
            context.reenableTaps()
            isEnabled = context.areTapsEnabled()
        }
        return TapHealth(isTapEnabled: isEnabled, isAccessibilityTrusted: isTrusted)
    }
}
