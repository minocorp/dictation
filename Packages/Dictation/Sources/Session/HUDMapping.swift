import Core

internal enum HUDMapping {
    static func hud(for failure: Failure) -> HUDState {
        switch failure {
        case .capture(let error): hud(for: error)
        case .speech(let error): hud(for: error)
        case .cleanup(let error): hud(for: error)
        case .store(let error): hud(for: error)
        case .hotkey(let error): hud(for: error)
        case .selection(let selection): hud(for: selection)
        case .insert(let outcome): hud(for: outcome)
        }
    }

    private static func hud(for error: CaptureError) -> HUDState {
        switch error {
        case .cancelled: .hidden
        case .permissionDenied: .problem(.microphoneDenied)
        case .noInputDevice, .deviceUnavailable, .alreadyRunning, .engineFailed:
            .problem(.microphoneUnavailable)
        case .diskWriteFailed: .problem(.couldNotSave)
        }
    }

    private static func hud(for error: SpeechError) -> HUDState {
        switch error {
        case .modelUnavailable: .saved
        case .cancelled, .unsupportedLanguage, .failed: .problem(.couldNotTranscribe)
        }
    }

    private static func hud(for error: CleanupError) -> HUDState {
        switch error {
        case .cancelled, .modelUnavailable, .timedOut, .rejected, .failed: .problem(.couldNotEdit)
        }
    }

    private static func hud(for error: StoreError) -> HUDState {
        switch error {
        case .cancelled, .readFailed: .hidden
        case .notFound, .writeFailed, .fileFailed: .problem(.couldNotSave)
        }
    }

    private static func hud(for error: HotkeyError) -> HUDState {
        switch error {
        case .cancelled: .hidden
        case .accessibilityNotTrusted, .eventTapUnavailable: .problem(.accessibilityOff)
        }
    }

    private static func hud(for selection: Selection) -> HUDState {
        switch selection {
        case .text, .none: .hidden
        case .tooLong: .problem(.selectionTooLong)
        case .unreadable: .problem(.couldNotEdit)
        }
    }

    private static func hud(for outcome: InsertOutcome) -> HUDState {
        switch outcome {
        case .inserted: .hidden
        case .copied: .copied
        case .refused(let reason): hud(for: reason)
        }
    }

    private static func hud(for reason: RefusalReason) -> HUDState {
        switch reason {
        case .secureField: .problem(.passwordField)
        }
    }
}
