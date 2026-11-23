import Core

internal enum SystemEvent: Equatable, Sendable {
    case permission(PermissionStatus)
    case preferences(Preferences)
    case hotkeyFailed(HotkeyError)
    case systemSleep
    case screenLocked
}
