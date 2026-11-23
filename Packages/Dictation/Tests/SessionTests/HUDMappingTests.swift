import Core
@testable import Session
import Testing

internal struct HUDMappingTests {
    struct Case: Sendable, CustomTestStringConvertible {
        let failure: Failure
        let hud: HUDState

        var testDescription: String { "\(failure)" }
    }

    private static let cases: [Case] = [
        Case(failure: .capture(.cancelled), hud: .hidden),
        Case(failure: .capture(.permissionDenied), hud: .problem(.microphoneDenied)),
        Case(failure: .capture(.noInputDevice), hud: .problem(.microphoneUnavailable)),
        Case(failure: .capture(.deviceUnavailable), hud: .problem(.microphoneUnavailable)),
        Case(failure: .capture(.alreadyRunning), hud: .problem(.microphoneUnavailable)),
        Case(failure: .capture(.engineFailed(code: 1)), hud: .problem(.microphoneUnavailable)),
        Case(failure: .capture(.diskWriteFailed(code: 1)), hud: .problem(.couldNotSave)),
        Case(failure: .speech(.cancelled), hud: .problem(.couldNotTranscribe)),
        Case(failure: .speech(.modelUnavailable), hud: .saved),
        Case(failure: .speech(.unsupportedLanguage), hud: .problem(.couldNotTranscribe)),
        Case(failure: .speech(.failed(code: 1)), hud: .problem(.couldNotTranscribe)),
        Case(failure: .cleanup(.cancelled), hud: .problem(.couldNotEdit)),
        Case(failure: .cleanup(.modelUnavailable), hud: .problem(.couldNotEdit)),
        Case(failure: .cleanup(.timedOut), hud: .problem(.couldNotEdit)),
        Case(failure: .cleanup(.rejected), hud: .problem(.couldNotEdit)),
        Case(failure: .cleanup(.failed(code: 1)), hud: .problem(.couldNotEdit)),
        Case(failure: .store(.cancelled), hud: .hidden),
        Case(failure: .store(.notFound), hud: .problem(.couldNotSave)),
        Case(failure: .store(.readFailed(code: 1)), hud: .hidden),
        Case(failure: .store(.writeFailed(code: 1)), hud: .problem(.couldNotSave)),
        Case(failure: .store(.fileFailed(code: 1)), hud: .problem(.couldNotSave)),
        Case(failure: .hotkey(.cancelled), hud: .hidden),
        Case(failure: .hotkey(.accessibilityNotTrusted), hud: .problem(.accessibilityOff)),
        Case(failure: .hotkey(.eventTapUnavailable), hud: .problem(.accessibilityOff)),
        Case(failure: .selection(.text("x")), hud: .hidden),
        Case(failure: .selection(.none), hud: .hidden),
        Case(failure: .selection(.tooLong), hud: .problem(.selectionTooLong)),
        Case(failure: .selection(.unreadable), hud: .problem(.couldNotEdit)),
        Case(failure: .insert(.inserted(.pasteShortcut)), hud: .hidden),
        Case(failure: .insert(.inserted(.pasteMenu)), hud: .hidden),
        Case(failure: .insert(.inserted(.typedUnicode)), hud: .hidden),
        Case(failure: .insert(.copied(.targetLostFocus)), hud: .copied),
        Case(failure: .insert(.copied(.noTextField)), hud: .copied),
        Case(failure: .insert(.copied(.modifiersHeld)), hud: .copied),
        Case(failure: .insert(.copied(.composingTimeout)), hud: .copied),
        Case(failure: .insert(.copied(.allMethodsFailed)), hud: .copied),
        Case(failure: .insert(.refused(.secureField)), hud: .problem(.passwordField)),
    ]

    @Test(arguments: cases)
    func everyErrorAndOutcomeMapsToOneHUD(_ scenario: Case) {
        #expect(HUDMapping.hud(for: scenario.failure) == scenario.hud)
    }

    @Test(arguments: [
        (HUDState.copied, Duration.seconds(3)),
        (.canceled, .seconds(5)),
        (.saved, .seconds(2)),
        (.noSpeech, .milliseconds(1_500)),
        (.problem(.microphoneUnavailable), .seconds(8)),
    ])
    func transientStatesExpire(hud: HUDState, expiry: Duration) {
        #expect(SessionTiming.expiry(of: hud) == expiry)
    }

    @Test(arguments: [HUDState.hidden, .listening, .editing, .processing])
    func liveStatesNeverExpire(_ hud: HUDState) {
        #expect(SessionTiming.expiry(of: hud) == nil)
    }
}
