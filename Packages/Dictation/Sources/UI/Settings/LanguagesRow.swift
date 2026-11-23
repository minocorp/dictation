import Core
import SwiftUI

internal struct LanguagesRow: View {
    let model: SettingsModel

    var body: some View {
        LabeledContent(UIString.settingsLanguages) {
            FlowLayout(spacing: 6) {
                ForEach(model.preferences.languages, id: \.identifier) { language in
                    LanguageChip(name: model.languageName(language)) {
                        model.removeLanguage(language)
                    }
                }
                addMenu
            }
        }
    }

    private var addMenu: some View {
        Menu {
            ForEach(model.addableLanguages, id: \.identifier) { language in
                Button {
                    model.addLanguage(language)
                } label: {
                    Text(verbatim: model.languageName(language))
                }
            }
        } label: {
            Image(systemName: "plus")
                .foregroundStyle(.primary)
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .fixedSize()
        .accessibilityLabel(Text(UIString.settingsAddLanguage))
        .disabled(model.addableLanguages.isEmpty)
    }
}
