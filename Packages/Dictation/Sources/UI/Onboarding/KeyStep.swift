import Core
import SwiftUI

internal struct KeyStep: View {
    let model: OnboardingModel

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if !model.isKeyConfirmed {
                Text(UIString.obKeyPrompt)
                    .foregroundStyle(.secondary)
            }
            KeyRecorderView(model: model.keyRecorder)
            GlobeAdviceView(model: model.settings)
        }
        .task(id: model.activeStep) {
            if model.activeStep == .key { model.keyRecorder.begin() }
        }
    }
}
