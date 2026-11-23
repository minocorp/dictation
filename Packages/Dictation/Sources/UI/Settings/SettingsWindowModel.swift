public import Observation

@MainActor
@Observable
public final class SettingsWindowModel {
    var selection = SettingsPane.general

    let settings: SettingsModel
    let dictionary: DictionaryModel
    let models: ModelsModel
    let about: AboutModel

    public init(
        settings: SettingsModel,
        dictionary: DictionaryModel,
        models: ModelsModel,
        about: AboutModel,
    ) {
        self.settings = settings
        self.dictionary = dictionary
        self.models = models
        self.about = about
    }

    public func show(_ destination: SettingsDestination) {
        selection =
            switch destination {
            case .general: .general
            case .dictionary: .dictionary
            case .models: .models
            case .history: .history
            case .about: .about
            }
    }
}
