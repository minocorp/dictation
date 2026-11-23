import Core
import SwiftUI

internal struct MicrophoneStep: View {
    let model: OnboardingModel

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if model.isMicrophoneGranted {
                LevelMeterView(level: model.level)
                if model.showsBluetoothNote {
                    Text(UIString.obMicrophoneBluetooth)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
            } else if model.isMicrophoneDenied {
                Button(UIString.obOpenSettings) {
                    Task { await model.openSettings(for: .microphone) }
                }
            } else {
                Button(UIString.obMicrophoneAllow) {
                    Task { await model.allowMicrophone() }
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }
}
