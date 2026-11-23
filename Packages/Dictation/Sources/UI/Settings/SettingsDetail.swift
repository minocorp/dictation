import SwiftUI

internal struct SettingsDetail: View {
    let model: SettingsWindowModel

    var body: some View {
        switch model.selection {
        case .general: GeneralPane(model: model.settings)
        case .dictionary: DictionaryPane(settings: model.settings, model: model.dictionary)
        case .models: ModelsPane(model: model.models)
        case .history: HistoryPane(model: model.settings)
        case .about: AboutPane(model: model.about)
        }
    }
}
