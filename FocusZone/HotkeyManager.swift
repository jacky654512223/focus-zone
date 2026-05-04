import AppKit

/// Registers a global keyboard shortcut to toggle Focus Zone.
/// Reads the key code and modifiers from Preferences.
/// Uses both global and local event monitors so the hotkey works regardless
/// of which app is focused.
final class HotkeyManager {
    var onHotkeyPressed: (() -> Void)?

    private var globalMonitor: Any?
    private var localMonitor: Any?

    private var keyCode: UInt16
    private var modifierFlags: NSEvent.ModifierFlags

    init() {
        let prefs = Preferences.shared
        self.keyCode = UInt16(prefs.hotkeyKeyCode)
        self.modifierFlags = NSEvent.ModifierFlags(rawValue: UInt(prefs.hotkeyModifiers))
    }

    /// Update the hotkey binding. Restarts monitors if currently running.
    func updateHotkey(keyCode: UInt16, modifiers: NSEvent.ModifierFlags) {
        self.keyCode = keyCode
        self.modifierFlags = modifiers
        if globalMonitor != nil {
            stop()
            start()
        }
    }

    func start() {
        guard globalMonitor == nil else { return }

        // Global monitor — fires when another app is focused
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handleKeyEvent(event)
        }

        // Local monitor — fires when Focus Zone itself is focused
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if self?.handleKeyEvent(event) == true {
                return nil // consume the event
            }
            return event
        }
    }

    func stop() {
        if let globalMonitor {
            NSEvent.removeMonitor(globalMonitor)
        }
        if let localMonitor {
            NSEvent.removeMonitor(localMonitor)
        }
        globalMonitor = nil
        localMonitor = nil
    }

    @discardableResult
    private func handleKeyEvent(_ event: NSEvent) -> Bool {
        let requiredMods = modifierFlags.intersection(.deviceIndependentFlagsMask)
        let eventMods = event.modifierFlags.intersection(.deviceIndependentFlagsMask)

        if event.keyCode == keyCode && eventMods == requiredMods {
            onHotkeyPressed?()
            return true
        }
        return false
    }
}
