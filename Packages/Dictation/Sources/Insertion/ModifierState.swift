import Core

internal protocol ModifierState: Sendable {
    func heldModifiers() -> KeyModifiers
}
