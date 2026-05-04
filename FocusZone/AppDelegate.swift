import AppKit
import Combine

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusBarController: StatusBarController?
    private var overlayManager: OverlayManager?
    private var hotkeyManager: HotkeyManager?
    private var selectionWindow: SelectionOverlayWindow?
    private var cancellables = Set<AnyCancellable>()

    func applicationDidFinishLaunching(_ notification: Notification) {
        let prefs = Preferences.shared

        overlayManager = OverlayManager()
        hotkeyManager = HotkeyManager()
        statusBarController = StatusBarController()

        // Restore saved focus region
        if let saved = prefs.focusRegion {
            overlayManager?.updateFocusRegion(saved)
        }

        // Toggle dimming on/off
        prefs.$isEnabled
            .sink { [weak self] enabled in
                if enabled { self?.overlayManager?.showOverlays() }
                else       { self?.overlayManager?.hideOverlays() }
            }
            .store(in: &cancellables)

        prefs.$blurRadius
            .sink { [weak self] radius in self?.overlayManager?.updateBlur(radius) }
            .store(in: &cancellables)

        prefs.$dimOpacity
            .sink { [weak self] opacity in self?.overlayManager?.updateDim(opacity) }
            .store(in: &cancellables)

        // ⌘⇧D — toggle dimming
        hotkeyManager?.onTogglePressed = { prefs.isEnabled.toggle() }

        // ⌘⇧S — enter selection mode
        hotkeyManager?.onSelectPressed = { [weak self] in self?.enterSelectionMode() }

        prefs.$hotkeyEnabled
            .sink { [weak self] enabled in
                if enabled { self?.hotkeyManager?.start() }
                else       { self?.hotkeyManager?.stop() }
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

        if prefs.isEnabled  { overlayManager?.showOverlays() }
        if prefs.hotkeyEnabled { hotkeyManager?.start() }
    }

    func applicationWillTerminate(_ notification: Notification) {
        overlayManager?.hideOverlays()
        hotkeyManager?.stop()
    }

    // MARK: - Selection mode

    func enterSelectionMode() {
        guard selectionWindow == nil else { return }
        guard let screen = NSScreen.main else { return }

        // Activate the app so the selection window can receive mouse/keyboard events.
        // Menu bar apps are not normally "active", so without this the overlay
        // window appears but ignores all input.
        NSApplication.shared.activate(ignoringOtherApps: true)

        overlayManager?.hideOverlays()

        let win = SelectionOverlayWindow(screen: screen)
        selectionWindow = win

        win.onRegionSelected = { [weak self] screenRect in
            guard let self else { return }
            Preferences.shared.focusRegion = screenRect
            self.overlayManager?.updateFocusRegion(screenRect)
            if Preferences.shared.isEnabled { self.overlayManager?.showOverlays() }
            self.selectionWindow = nil
        }

        win.onCancelled = { [weak self] in
            guard let self else { return }
            if Preferences.shared.isEnabled { self.overlayManager?.showOverlays() }
            self.selectionWindow = nil
        }

        win.makeKeyAndOrderFront(nil)
    }
}
