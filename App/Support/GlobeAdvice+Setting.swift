import Hotkeys
import UI

extension GlobeAdvice {
    init(_ setting: GlobeSetting) {
        self =
            switch setting.usage {
            case .doNothing: .none
            case .changeInputSource: .changesInputSource
            case .showEmojiAndSymbols: .showsEmoji
            case .startDictation: .startsDictation
            case .other: .other
            }
    }
}
