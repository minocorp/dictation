import UI

@MainActor
internal final class AppActions {
    var showSettings: @MainActor (SettingsDestination) -> Void = { _ in }
    var showHistory: @MainActor () -> Void = {}
    var finishOnboarding: @MainActor () -> Void = {}
}
