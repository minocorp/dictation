public import Core

public struct SessionState: Equatable, Sendable {
    public internal(set) var hud: HUDState
    public internal(set) var lastResult: LastResult?
    public internal(set) var permissions: PermissionStatus
    var active: Active?
    var queue: [Pending]
    var preferences: Preferences
    var notice: HUDState?
    var indicator: ProcessingIndicator

    public var isIdle: Bool { active == nil && queue.isEmpty }
    public var isLive: Bool { active != nil }

    var dictationIDs: Set<DictationID> {
        Set(queue.map(\.id) + [active?.pending.id].compactMap { $0 })
    }

    public init(preferences: Preferences, permissions: PermissionStatus) {
        hud = .hidden
        lastResult = nil
        self.permissions = permissions
        active = nil
        queue = []
        self.preferences = preferences
        notice = nil
        indicator = .off
    }

    var tapPolicy: TapPolicy {
        TapPolicy(
            dictateKey: preferences.dictateKey,
            pasteLast: preferences.pasteLastShortcut,
            swallowsEscape: active != nil,
        )
    }
}
