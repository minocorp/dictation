import SwiftUI

internal struct GlobeAdviceView: View {
    let model: SettingsModel

    var body: some View {
        if let message = model.globeAdvice.message {
            VStack(alignment: .leading, spacing: 8) {
                Text(message)
                    .foregroundStyle(.secondary)
                HStack {
                    Button(UIString.keyOpenKeyboardSettings, action: model.openKeyboardSettings)
                    Button(UIString.keyUseRightOption, action: model.useRightOption)
                        .buttonStyle(.borderedProminent)
                }
            }
        }
    }
}
