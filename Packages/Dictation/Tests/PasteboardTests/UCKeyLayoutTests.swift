import Carbon
import Foundation
@testable import Pasteboard
import Testing

internal struct UCKeyLayoutTests {
    private struct Case: Sendable {
        let layoutID: String
        let shortcut: ClipboardShortcut
        let keyCode: UInt16
    }

    private static let cases = [
        Case(layoutID: "com.apple.keylayout.US", shortcut: .paste, keyCode: 9),
        Case(layoutID: "com.apple.keylayout.US", shortcut: .copy, keyCode: 8),
        Case(layoutID: "com.apple.keylayout.Dvorak", shortcut: .paste, keyCode: 47),
        Case(layoutID: "com.apple.keylayout.DVORAK-QWERTYCMD", shortcut: .paste, keyCode: 9),
    ]

    @MainActor
    @Test(arguments: cases)
    private func resolvesAgainstTheSystemLayout(testCase: Case) throws {
        let layout = try #require(Self.layout(withID: testCase.layoutID))
        #expect(KeyCodeResolver.keyCode(for: testCase.shortcut, in: layout) == testCase.keyCode)
    }

    @MainActor
    private static func layout(withID layoutID: String) -> UCKeyLayout? {
        let filter = [kTISPropertyInputSourceID as String: layoutID] as CFDictionary
        guard
            let list = TISCreateInputSourceList(filter, true)?.takeRetainedValue()
                as? [TISInputSource],
            let source = list.first,
            let property = TISGetInputSourceProperty(source, kTISPropertyUnicodeKeyLayoutData)
        else { return nil }
        let data = Unmanaged<CFData>.fromOpaque(property).takeUnretainedValue()
        return UCKeyLayout(
            layoutData: Data(bytes: CFDataGetBytePtr(data), count: CFDataGetLength(data))
        )
    }
}
