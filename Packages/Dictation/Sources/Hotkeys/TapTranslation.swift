import Core

internal struct TapTranslation: Hashable, Sendable {
    let event: RawKeyEvent
    let isRepeat: Bool
}
