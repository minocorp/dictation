import Core

internal enum TapTranslator {
    private static let keysSettingFunctionFlag: Set<UInt16> = [
        96, 97, 98, 99, 100, 101, 103, 105, 107, 109, 111, 113, 114, 115, 116, 117, 118, 119, 120,
        121, 122, 123, 124, 125, 126,
    ]

    static func translate(_ input: TapInput) -> TapTranslation? {
        switch input.kind {
        case .keyDown:
            keyTranslation(input, phase: .pressed)
        case .keyUp:
            keyTranslation(input, phase: .released)
        case .flagsChanged:
            modifierTranslation(input)
        case .mouseDown:
            mouseTranslation(input, phase: .pressed)
        case .mouseUp:
            mouseTranslation(input, phase: .released)
        }
    }

    private static func keyTranslation(
        _ input: TapInput,
        phase: RawKeyEvent.Phase,
    )
        -> TapTranslation
    {
        let modifiers = KeyModifiers(
            flags: input.flags,
            includesFunction: !keysSettingFunctionFlag.contains(input.keyCode),
        )
        return TapTranslation(
            event: RawKeyEvent(
                phase: phase,
                trigger: .key(code: input.keyCode),
                modifiers: modifiers,
            ),
            isRepeat: input.isRepeat,
        )
    }

    private static func modifierTranslation(_ input: TapInput) -> TapTranslation? {
        guard let key = ModifierKey(rawValue: input.keyCode) else { return nil }
        let phase = input.flags.contains(key.pressedFlag) ? RawKeyEvent.Phase.pressed : .released
        return TapTranslation(
            event: RawKeyEvent(
                phase: phase,
                trigger: .key(code: input.keyCode),
                modifiers: KeyModifiers(flags: input.flags),
            ),
            isRepeat: false,
        )
    }

    private static func mouseTranslation(
        _ input: TapInput,
        phase: RawKeyEvent.Phase,
    )
        -> TapTranslation
    {
        TapTranslation(
            event: RawKeyEvent(
                phase: phase,
                trigger: .mouseButton(input.mouseButton),
                modifiers: KeyModifiers(flags: input.flags),
            ),
            isRepeat: false,
        )
    }
}
