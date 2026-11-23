import Core

internal protocol FrontmostAppSource: Sendable {
    func frontmost() -> TargetApp?
}
