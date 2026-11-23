import AudioToolbox
import Core
import Foundation

internal struct AppSoundPlayer: SoundPlayer {
    private let start: SystemSoundID
    private let finish: SystemSoundID
    private let cancel: SystemSoundID

    init() {
        start = Self.load("Tink")
        finish = Self.load("Purr")
        cancel = Self.load("Basso")
    }

    func play(_ sound: Sound) {
        let identifier =
            switch sound {
            case .start: start
            case .finish: finish
            case .cancel: cancel
            }
        AudioServicesPlaySystemSound(identifier)
    }

    private static func load(_ name: String) -> SystemSoundID {
        var identifier: SystemSoundID = 0
        let url = URL(filePath: "/System/Library/Sounds/\(name).aiff")
        AudioServicesCreateSystemSoundID(url as CFURL, &identifier)
        return identifier
    }
}
