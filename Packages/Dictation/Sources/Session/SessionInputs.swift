public import Core

public struct SessionInputs: Sendable {
    let keys: any KeySource
    let audio: any AudioSource
    let voice: any VoiceActivity
    let files: any AudioFileSegmenter

    public init(
        keys: any KeySource,
        audio: any AudioSource,
        voice: any VoiceActivity,
        files: any AudioFileSegmenter,
    ) {
        self.keys = keys
        self.audio = audio
        self.voice = voice
        self.files = files
    }
}
