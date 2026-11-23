import AppKit

internal struct SystemUnicodeTyper: UnicodeTyper {
    private static let maxUnitsPerEvent = 20

    func type(_ text: String) -> Bool {
        guard AXIsProcessTrusted(), let source = CGEventSource(stateID: .privateState) else {
            return false
        }
        for chunk in Self.chunks(of: text) {
            guard Self.post(chunk, source: source) else { return false }
        }
        return true
    }

    private static func chunks(of text: String) -> [[UniChar]] {
        var chunks: [[UniChar]] = []
        var current: [UniChar] = []
        for character in text {
            let units = Array(String(character).utf16)
            if current.count + units.count > maxUnitsPerEvent {
                chunks.append(current)
                current = []
            }
            current += units
        }
        if !current.isEmpty { chunks.append(current) }
        return chunks
    }

    private static func post(_ units: [UniChar], source: CGEventSource) -> Bool {
        let events = [true, false]
            .compactMap { isDown in
                CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: isDown)
            }
        guard events.count == 2 else { return false }
        for event in events {
            event.flags = []
            event.keyboardSetUnicodeString(stringLength: units.count, unicodeString: units)
            event.post(tap: .cghidEventTap)
        }
        return true
    }
}
