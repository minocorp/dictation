import Core

extension RawKeyEvent {
    static let fnDown = RawKeyEvent(
        phase: .pressed,
        trigger: .key(code: 63),
        modifiers: [.function],
    )
    static let fnUp = RawKeyEvent(phase: .released, trigger: .key(code: 63), modifiers: [])
    static let fnDownWithControl = RawKeyEvent(
        phase: .pressed,
        trigger: .key(code: 63),
        modifiers: [.function, .control],
    )
    static let fnUpWithControl = RawKeyEvent(
        phase: .released,
        trigger: .key(code: 63),
        modifiers: [.control],
    )
    static let fnDownWithShift = RawKeyEvent(
        phase: .pressed,
        trigger: .key(code: 63),
        modifiers: [.function, .shift],
    )
    static let fnDownWithControlShift = RawKeyEvent(
        phase: .pressed,
        trigger: .key(code: 63),
        modifiers: [.function, .control, .shift],
    )
    static let globeDown = RawKeyEvent(
        phase: .pressed,
        trigger: .key(code: 179),
        modifiers: [.function],
    )
    static let globeUp = RawKeyEvent(phase: .released, trigger: .key(code: 179), modifiers: [])
    static let escapeDown = RawKeyEvent(phase: .pressed, trigger: .escape, modifiers: [])
    static let escapeUp = RawKeyEvent(phase: .released, trigger: .escape, modifiers: [])
    static let escapeDownWithCommand = RawKeyEvent(
        phase: .pressed,
        trigger: .escape,
        modifiers: [.command],
    )
    static let escapeDownWithFunction = RawKeyEvent(
        phase: .pressed,
        trigger: .escape,
        modifiers: [.function],
    )
    static let escapeDownWithOption = RawKeyEvent(
        phase: .pressed,
        trigger: .escape,
        modifiers: [.option],
    )
    static let escapeDownWithFunctionControl = RawKeyEvent(
        phase: .pressed,
        trigger: .escape,
        modifiers: [.function, .control],
    )
    static let pasteDown = RawKeyEvent(
        phase: .pressed,
        trigger: .key(code: 9),
        modifiers: [.control, .command],
    )
    static let pasteUp = RawKeyEvent(
        phase: .released,
        trigger: .key(code: 9),
        modifiers: [.command],
    )
    static let pasteDownWithCommandOnly = RawKeyEvent(
        phase: .pressed,
        trigger: .key(code: 9),
        modifiers: [.command],
    )
    static let pasteDownWithShift = RawKeyEvent(
        phase: .pressed,
        trigger: .key(code: 9),
        modifiers: [.control, .command, .shift],
    )
    static let rightOptionDown = RawKeyEvent(
        phase: .pressed,
        trigger: .key(code: 61),
        modifiers: [.option],
    )
    static let rightOptionUp = RawKeyEvent(
        phase: .released,
        trigger: .key(code: 61),
        modifiers: [],
    )
    static let rightCommandDown = RawKeyEvent(
        phase: .pressed,
        trigger: .key(code: 54),
        modifiers: [.command],
    )
    static let rightCommandUp = RawKeyEvent(
        phase: .released,
        trigger: .key(code: 54),
        modifiers: [],
    )
    static let copyDownWithCommand = RawKeyEvent(
        phase: .pressed,
        trigger: .key(code: 8),
        modifiers: [.command],
    )
    static let copyUp = RawKeyEvent(phase: .released, trigger: .key(code: 8), modifiers: [])
    static let mouseDown = RawKeyEvent(phase: .pressed, trigger: .mouseButton(3), modifiers: [])
    static let mouseUp = RawKeyEvent(phase: .released, trigger: .mouseButton(3), modifiers: [])
    static let letterDown = RawKeyEvent(phase: .pressed, trigger: .key(code: 0), modifiers: [])
    static let functionKeyDown = RawKeyEvent(
        phase: .pressed,
        trigger: .key(code: 96),
        modifiers: [.command],
    )
    static let functionKeyDownBare = RawKeyEvent(
        phase: .pressed,
        trigger: .key(code: 96),
        modifiers: [],
    )
    static let functionKeyUp = RawKeyEvent(
        phase: .released,
        trigger: .key(code: 96),
        modifiers: [],
    )
}
