import UI

@MainActor
internal final class AppActions {
    var showSettings: @MainActor (SettingsPane) -> Void = { _ in }
    var showHistory: @MainActor () -> Void = {}
    var finishOnboarding: @MainActor () -> Void = {}
}
