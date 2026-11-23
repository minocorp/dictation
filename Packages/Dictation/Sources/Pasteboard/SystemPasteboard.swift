import AppKit
package import Foundation

package struct SystemPasteboard: PasteboardAccess {
    private static let derivedTypePrefix = "dyn."

    package var changeCount: Int { NSPasteboard.general.changeCount }

    package init() {}

    package func items() -> [PasteboardItem] {
        let items = NSPasteboard.general.pasteboardItems ?? []
        return items.compactMap(Self.snapshot)
    }

    package func replace(with items: [PasteboardItem]) -> Int {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        let objects = items.map { item in
            let object = NSPasteboardItem()
            for type in item.orderedTypes {
                guard let data = item.representations[type] else { continue }
                object.setData(data, forType: NSPasteboard.PasteboardType(type))
            }
            return object
        }
        if !objects.isEmpty {
            pasteboard.writeObjects(objects)
        }
        return pasteboard.changeCount
    }

    package func data(forType type: String) -> Data? {
        NSPasteboard.general.data(forType: NSPasteboard.PasteboardType(type))
    }

    private static func snapshot(of item: NSPasteboardItem) -> PasteboardItem? {
        var representations: [String: Data] = [:]
        var orderedTypes: [String] = []
        for type in item.types where !type.rawValue.hasPrefix(derivedTypePrefix) {
            guard representations[type.rawValue] == nil, let data = item.data(forType: type)
            else { continue }
            representations[type.rawValue] = data
            orderedTypes.append(type.rawValue)
        }
        guard !orderedTypes.isEmpty else { return nil }
        return PasteboardItem(representations: representations, orderedTypes: orderedTypes)
    }
}
