import Core
import SwiftUI

internal struct OnboardingStepStatus: View {
    let model: OnboardingModel
    let step: OnboardingStep

    var body: some View {
        switch step {
        case .microphone where model.isMicrophoneGranted:
            Text(UIString.obAllowed)
                .foregroundStyle(.green)
        case .accessibility where model.permissions.isAccessibilityTrusted:
            Text(UIString.obDetected)
                .foregroundStyle(.green)
        case .microphone, .accessibility, .key, .tryIt:
            EmptyView()
        }
    }
}
