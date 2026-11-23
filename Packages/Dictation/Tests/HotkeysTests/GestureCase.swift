import Core
import Testing

internal struct GestureCase: Sendable, CustomTestStringConvertible {
    struct Step: Sendable {
        let atMs: Int
        let event: RawKeyEvent
        let expected: [Gesture]

        static func at(_ atMs: Int, _ event: RawKeyEvent, _ expected: [Gesture]) -> Step {
            Step(atMs: atMs, event: event, expected: expected)
        }
    }

    let name: String
    let dictateKey: KeyBinding
    let steps: [Step]

    var testDescription: String { name }

    init(_ name: String, dictateKey: KeyBinding = .fn, steps: [Step]) {
        self.name = name
        self.dictateKey = dictateKey
        self.steps = steps
    }
}
