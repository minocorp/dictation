import ServiceManagement

internal enum LaunchAtLogin {
    static func apply(_ isEnabled: Bool) {
        let service = SMAppService.mainApp
        do {
            if isEnabled, service.status != .enabled {
                try service.register()
            } else if !isEnabled, service.status == .enabled {
                try service.unregister()
            }
        } catch {
            AppLog.failure("launch at login", error)
        }
    }
}
