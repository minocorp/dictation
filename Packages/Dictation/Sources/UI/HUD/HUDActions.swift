public import Core

public struct HUDActions {
    let perform: @MainActor (Gesture) -> Void
    let openFix: @MainActor (HUDFix) -> Void
    let announce: @MainActor (String) -> Void

    public init(
        perform: @escaping @MainActor (Gesture) -> Void,
        openFix: @escaping @MainActor (HUDFix) -> Void,
        announce: @escaping @MainActor (String) -> Void,
    ) {
        self.perform = perform
        self.openFix = openFix
        self.announce = announce
    }
}
