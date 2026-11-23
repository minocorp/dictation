public import Core
import Synchronization

public final class FakeSoundPlayer: SoundPlayer {
    private let playedSounds = Mutex<[Sound]>([])

    public var played: [Sound] { playedSounds.withLock { $0 } }

    public init() {}

    public func play(_ sound: Sound) {
        playedSounds.withLock { $0.append(sound) }
    }
}
