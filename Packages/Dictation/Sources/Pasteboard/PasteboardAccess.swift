package import Foundation

package protocol PasteboardAccess: Sendable {
    var changeCount: Int { get }
    func items() -> [PasteboardItem]
    func replace(with items: [PasteboardItem]) -> Int
    func data(forType type: String) -> Data?
}
