import Carbon
import Foundation

package struct SystemKeyboardLayoutSource: KeyboardLayoutSource {
    package init() {}

    package func currentLayout() async -> (any KeyTranslating)? {
        await MainActor.run { Self.layoutOfCurrentSource() }
    }

    @MainActor
    private static func layoutOfCurrentSource() -> UCKeyLayout? {
        let sources = [
            TISCopyCurrentKeyboardLayoutInputSource(),
            TISCopyCurrentASCIICapableKeyboardLayoutInputSource(),
        ]
        for source in sources {
            if let source, let data = layoutData(of: source.takeRetainedValue()) {
                return UCKeyLayout(layoutData: data)
            }
        }
        return nil
    }

    @MainActor
    private static func layoutData(of source: TISInputSource) -> Data? {
        guard let property = TISGetInputSourceProperty(source, kTISPropertyUnicodeKeyLayoutData)
        else { return nil }
        let data = Unmanaged<CFData>.fromOpaque(property).takeUnretainedValue()
        return Data(bytes: CFDataGetBytePtr(data), count: CFDataGetLength(data))
    }
}
