import Core
import SwiftUI

internal struct OnboardingStepRow: View {
    let model: OnboardingModel
    let step: OnboardingStep

    private var isActive: Bool { model.activeStep == step }
    private var isComplete: Bool {
        switch step {
        case .microphone: model.isMicrophoneGranted
        case .accessibility: model.permissions.isAccessibilityTrusted
        case .key: model.isKeyConfirmed
        case .tryIt: false
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            OnboardingStepBadge(
                number: step.rawValue + 1,
                isActive: isActive,
                isComplete: isComplete,
            )
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(step.title)
                        .font(.headline)
                        .foregroundStyle(isActive || isComplete ? .primary : .secondary)
                    Spacer()
                    OnboardingStepStatus(model: model, step: step)
                }
                if isActive || isComplete {
                    OnboardingStepContent(model: model, step: step)
                }
            }
        }
        .padding(.vertical, 14)
        .animation(.default, value: isActive)
    }
}
