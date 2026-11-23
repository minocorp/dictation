import Core
import SwiftUI

internal struct TryItStep: View {
    let model: OnboardingModel

    @State
    private var text = ""
    @FocusState
    private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            TextEditor(text: $text)
                .focused($isFocused)
                .font(.body)
                .scrollContentBackground(.hidden)
                .padding(6)
                .frame(height: 96)
                .background(.background, in: RoundedRectangle(cornerRadius: 8))
                .overlay { RoundedRectangle(cornerRadius: 8).strokeBorder(.quaternary) }
            ModelDownloadStatus(model: model)
        }
        .task { isFocused = true }
    }
}
