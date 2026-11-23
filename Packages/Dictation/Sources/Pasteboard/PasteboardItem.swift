package import Foundation

package struct PasteboardItem: Hashable, Sendable {
    package let orderedTypes: [String]
    package let representations: [String: Data]

    package init(representations: [String: Data], orderedTypes: [String]? = nil) {
        self.representations = representations
        self.orderedTypes = orderedTypes ?? representations.keys.sorted()
    }
}
