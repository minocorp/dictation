@testable import Pasteboard

internal struct FakeKeyLayout: KeyTranslating {
    let commandMap: [UInt16: String]

    static let qwerty = FakeKeyLayout(commandMap: [8: "c", 9: "v", 38: "j", 47: "."])
    static let dvorak = FakeKeyLayout(commandMap: [8: "j", 9: ".", 34: "c", 38: "h", 47: "v"])
    static let dvorakQwertyCommand = qwerty
    static let cyrillic = FakeKeyLayout(commandMap: [8: "с", 9: "м"])
    static let shouting = FakeKeyLayout(commandMap: [9: "V"])

    func characters(forKeyCode keyCode: UInt16, commandHeld: Bool) -> String {
        commandMap[keyCode] ?? ""
    }
}
