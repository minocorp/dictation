import Core
import SwiftUI

internal struct OnboardingStepContent: View {
    let model: OnboardingModel
    let step: OnboardingStep

    var body: some View {
        switch step {
        case .microphone: MicrophoneStep(model: model)
        case .accessibility: AccessibilityStep(model: model)
        case .key: KeyStep(model: model)
        case .tryIt: TryItStep(model: model)
        }
    }
}
