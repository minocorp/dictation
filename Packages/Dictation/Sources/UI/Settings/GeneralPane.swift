import Core
import SwiftUI

internal struct GeneralPane: View {
    @Bindable
    var model: SettingsModel
    @State
    private var dictateRecorder: KeyRecorderModel
    @State
    private var pasteLastRecorder: KeyRecorderModel

    init(model: SettingsModel) {
        self.model = model
        _dictateRecorder = State(initialValue: model.makeRecorder(.dictateKey))
        _pasteLastRecorder = State(initialValue: model.makeRecorder(.shortcut))
    }

    var body: some View {
        Form {
            Section {
                LabeledContent(UIString.settingsDictateKey) {
                    KeyRecorderView(model: dictateRecorder)
                }
                GlobeAdviceView(model: model)
                Picker(
                    UIString.settingsSilenceLimit,
                    selection: $model.preferences.handsFreeSilenceLimit,
                ) {
                    ForEach(HandsFreeSilenceLimit.allCases, id: \.self) { limit in
                        Text(limit.label).tag(limit)
                    }
                }
                LabeledContent(UIString.settingsPasteLastShortcut) {
                    KeyRecorderView(model: pasteLastRecorder)
                }
            }
            Section {
                Picker(UIString.settingsMicrophone, selection: $model.preferences.microphone) {
                    ForEach(model.microphones) { option in
                        microphoneLabel(option).tag(option.device)
                    }
                }
                LanguagesRow(model: model)
                Toggle(UIString.settingsCleanup, isOn: $model.preferences.cleanup)
                Toggle(UIString.settingsSounds, isOn: $model.preferences.sounds)
                Toggle(UIString.settingsLaunchAtLogin, isOn: $model.preferences.launchAtLogin)
            }
        }
        .formStyle(.grouped)
    }

    private func microphoneLabel(_ option: MicrophoneOption) -> Text {
        if let name = option.deviceName {
            Text(verbatim: name)
        } else {
            Text(UIString.settingsMicrophoneBuiltIn)
        }
    }
}
