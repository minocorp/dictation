public import SwiftUI

public struct KeyRecorderView: View {
    let model: KeyRecorderModel

    public init(model: KeyRecorderModel) {
        self.model = model
    }

    public var body: some View {
        HStack(spacing: 8) {
            if model.isRecording {
                Text(model.promptKey)
                    .foregroundStyle(.secondary)
                    .focusable()
                    .onKeyPress { _ in .handled }
                Button(UIString.commonCancel, action: model.cancel)
            } else {
                KeycapLabel(text: model.currentLabel)
                Button(UIString.keyRecord, action: model.begin)
                if !model.isDefault {
                    Button(UIString.keyReset, action: model.reset)
                }
            }
        }
    }
}
