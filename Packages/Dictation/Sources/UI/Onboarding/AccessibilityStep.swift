import Core
import SwiftUI

internal struct AccessibilityStep: View {
    let model: OnboardingModel

    var body: some View {
        if !model.permissions.isAccessibilityTrusted {
            Button(UIString.obOpenSettings) {
                Task { await model.openSettings(for: .accessibility) }
            }
            .buttonStyle(.borderedProminent)
        }
    }
}
