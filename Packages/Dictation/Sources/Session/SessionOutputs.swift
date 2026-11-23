public import Core

public struct SessionOutputs: Sendable {
    let focus: any FocusReader
    let inserter: any TextInserter
    let clipboard: any ClipboardWriter
    let sounds: any SoundPlayer

    public init(
        focus: any FocusReader,
        inserter: any TextInserter,
        clipboard: any ClipboardWriter,
        sounds: any SoundPlayer,
    ) {
        self.focus = focus
        self.inserter = inserter
        self.clipboard = clipboard
        self.sounds = sounds
    }
}
