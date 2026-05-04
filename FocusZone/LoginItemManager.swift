import ServiceManagement

/// Thin wrapper around SMAppService for launch-at-login on macOS 13+.
enum LoginItemManager {
    static func setEnabled(_ enabled: Bool) {
        let service = SMAppService.mainApp
        do {
            if enabled {
                try service.register()
            } else {
                try service.unregister()
            }
        } catch {
            print("LoginItemManager: failed to \(enabled ? "register" : "unregister") login item: \(error)")
        }
    }

    static var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }
}
