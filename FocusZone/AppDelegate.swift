import AppKit
import Carbon.HIToolbox
import Combine

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusBarController: StatusBarController?
    private var overlayManager: OverlayManager?
    private var hotkeyManager: HotkeyManager?
    private var selectionWindow: SelectionOverlayWindow?
    private var selectionHotkeyMonitor: Any?
    private var cancellables = Set<AnyCancellable>()

    func applicationDidFinishLaunching(_ notification: Notification) {
        let prefs = Preferences.shared

        overlayManager = OverlayManager()
        hotkeyManager = HotkeyManager()
        statusBarController = StatusBarController()

        // Restore saved focus region if available
        if let saved = prefs.focusRegion {
            overlayManager?.updateFocusRegion(saved)
        }

        // Toggle dimming on/off
        prefs.$isEnabled
            .sink { [weak self] enabled in
                if enabled {
                    self?.overlayManager?.showOverlays()
                } else {
                    self?.overlayManager?.hideOverlays()
                }
            }
            .store(in: &cancellables)

        prefs.$blurRadius
            .sink { [weak self] radius in
                self?.overlayManager?.updateBlur(radius)
            }
            .store(in: &cancellables)

        prefs.$dimOpacity
            .sink { [weak self] opacity in
                self?.overlayManager?.updateDim(opacity)
            }
            .store(in: &cancellables)

        // Cmd+Shift+D — toggle dimming (configurable via Settings)
        hotkeyManager?.onHotkeyPressed = {
            prefs.isEnabled.toggle()
        }

        prefs.$hotkeyEnabled
            .sink { [weak self] enabled in
                if enabled {
                    self?.hotkeyManager?.start()
                } else {
                    self?.hotkeyManager?.stop()
                }
            }
            .store(in: &cancellables)

        prefs.$hotkeyKeyCode
            .combineLatest(prefs.$hotkeyModifiers)
            .dropFirst()
            .sink { [weak self] keyCode, modifiers in
                self?.hotkeyManager?.updateHotkey(
                    keyCode: UInt16(keyCode),
                    modifiers: NSEvent.ModifierFlags(rawValue: UInt(modifiers))
                )
            }
            .store(in: &cancellables)

        // Cmd+Shift+S — enter selection mode (hardcoded)
        selectionHotkeyMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            let mods = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            if event.keyCode == UInt16(kVK_ANSI_S) && mods == [.command, .shift] {
                DispatchQueue.main.async { self?.enterSelectionMode() }
            }
        }

        if prefs.isEnabled {
            overlayManager?.showOverlays()
        }
        if prefs.hotkeyEnabled {
            hotkeyManager?.start()
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        overlayManager?.hideOverlays()
        hotkeyManager?.stop()
        if let monitor = selectionHotkeyMonitor {
            NSEvent.removeMonitor(monitor)
        }
    }

    // MARK: - Selection mode

    func enterSelectionMode() {
        guard selectionWindow == nil else { return }   // already in selection mode
        guard let screen = NSScreen.main else { return }

        // Temporarily hide dimming so user can see full screen while drawing
        overlayManager?.hideOverlays()

        let win = SelectionOverlayWindow(screen: screen)
        selectionWindow = win

        win.onRegionSelected = { [weak self] screenRect in
            guard let self else { return }
            Preferences.shared.focusRegion = screenRect
            self.overlayManager?.updateFocusRegion(screenRect)
            if Preferences.shared.isEnabled {
                self.overlayManager?.showOverlays()
            }
            self.selectionWindow = nil
        }

        win.onCancelled = { [weak self] in
            guard let self else { return }
            if Preferences.shared.isEnabled {
                self.overlayManager?.showOverlays()
            }
            self.selectionWindow = nil
        }

        win.makeKeyAndOrderFront(nil)
    }
}
