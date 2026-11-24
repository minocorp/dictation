import Core
public import SwiftUI

public struct OnboardingView: View {
    let model: OnboardingModel

    public init(model: OnboardingModel) {
        self.model = model
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(OnboardingStep.allCases, id: \.self) { step in
                OnboardingStepRow(model: model, step: step)
                if step != OnboardingStep.allCases.last {
                    Divider()
                }
            }
            HStack {
                Spacer()
                Button(UIString.commonDone, action: model.finish)
                    .keyboardShortcut(.defaultAction)
                    .disabled(!model.canFinish)
            }
            .padding(.top, 16)
        }
        .padding(24)
        .frame(width: 520)
        .task { await model.watchPermissions() }
        .task(id: model.permissions.microphone) { await model.watchLevels() }
    }
}
