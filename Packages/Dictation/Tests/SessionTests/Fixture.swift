import Core
import Foundation
@testable import Session

internal enum Fixture {
    static let first = DictationID()
    static let second = DictationID()
    static let third = DictationID()
    static let date = Date(timeIntervalSince1970: 1_000)
    static let app = TargetApp(pid: 42, bundleID: "com.example.editor", name: "Editor")
    static let audioURL = URL(fileURLWithPath: "/tmp/audio.caf")
    static let granted = PermissionStatus(microphone: .granted, isAccessibilityTrusted: true)
    static let languages = [Locale(identifier: "en_US")]
    static let focus = FocusSnapshot(
        target: app,
        fieldKind: .multiLine,
        fieldID: 1,
        isSecure: false,
        isComposing: false,
        textBefore: nil,
    )
    static let preferences = Preferences.makeDefault(
        globeSwitchesInputSource: false,
        preferredLanguages: languages,
    )

    static func state(permissions: PermissionStatus = granted) -> SessionState {
        SessionState(preferences: preferences, permissions: permissions)
    }

    static func policy(swallowsEscape: Bool) -> TapPolicy {
        TapPolicy(
            dictateKey: preferences.dictateKey,
            pasteLast: preferences.pasteLastShortcut,
            swallowsEscape: swallowsEscape,
        )
    }

    static func stamp(_ id: DictationID) -> Stamp {
        Stamp(id: id, date: date)
    }

    static func gesture(_ gesture: Gesture, _ id: DictationID = first) -> Event {
        .gesture(gesture, stamp(id))
    }

    static func input(_ input: InputEvent, _ id: DictationID = first) -> Event {
        .input(id, input)
    }

    static func result(_ result: ResultEvent, _ id: DictationID = first) -> Event {
        .result(id, result)
    }

    static func segment(_ index: Int, _ id: DictationID = first) -> Segment {
        Segment(
            dictation: id,
            index: index,
            startSample: index * AudioChunk.sampleRate,
            audio: [Float](repeating: 0, count: AudioChunk.sampleRate),
            isFinal: false,
        )
    }

    static func transcribed(_ index: Int, _ text: String, _ id: DictationID = first) -> Event {
        result(.transcribed(index: index, result: .success(text)), id)
    }

    static func cleaned(_ index: Int, _ text: String, _ id: DictationID = first) -> Event {
        result(.cleaned(index: index, result: .success(text)), id)
    }

    static func play(
        _ events: [Event],
        from state: SessionState = Fixture.state(),
    ) -> (state: SessionState, effects: [Effect]) {
        var state = state
        var effects: [Effect] = []
        for event in events {
            effects = reduce(&state, event)
        }
        return (state, effects)
    }

    static func holdAndRelease(_ id: DictationID = first, focus: FocusSnapshot? = focus) -> [Event]
    {
        [
            gesture(.pressBegan, id),
            .timer(.tapThreshold),
            input(.started, id),
            input(.focus(focus), id),
        ]
    }

    static func finishedDictation(
        _ texts: [String],
        _ id: DictationID = first,
        focus: FocusSnapshot? = focus,
    ) -> [Event] {
        var events = holdAndRelease(id, focus: focus)
        for index in texts.indices {
            events.append(input(.segment(segment(index, id)), id))
        }
        events.append(gesture(.released, id))
        events.append(input(.segmentsEnded, id))
        for (index, text) in texts.enumerated() {
            events.append(transcribed(index, text, id))
            events.append(cleaned(index, text, id))
        }
        events.append(input(.finished(audioURL: audioURL), id))
        return events
    }

    static func item(
        _ id: DictationID = first,
        raw: String,
        final: String,
        status: HistoryItem.Status,
        duration: Duration = .seconds(1),
        audioURL: URL? = audioURL,
    ) -> HistoryItem {
        HistoryItem(
            id: id,
            date: date,
            appBundleID: app.bundleID,
            appName: app.name,
            kind: .dictation,
            rawText: raw,
            finalText: final,
            instruction: nil,
            audioURL: audioURL,
            duration: duration,
            status: status,
        )
    }
}
