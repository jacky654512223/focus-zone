import AppKit
import Carbon.HIToolbox

// File-scope reference so the @convention(c) callback can reach the instance
// without needing to capture it (which @convention(c) doesn't allow).
private var _hotkeyManagerRef: HotkeyManager?

/// Registers system-wide hotkeys using the Carbon RegisterEventHotKey API.
/// Unlike NSEvent monitors, Carbon hotkeys fire regardless of which app has
/// focus — even if another app has already claimed the same key combination.
final class HotkeyManager {
    /// Called when the toggle-dim hotkey is pressed.
    var onTogglePressed: (() -> Void)?
    /// Called when the select-region hotkey (⌘⇧S) is pressed.
    var onSelectPressed: (() -> Void)?

    private var toggleHotKeyRef: EventHotKeyRef?
    private var selectHotKeyRef: EventHotKeyRef?
    private var eventHandlerRef: EventHandlerRef?

    private var toggleKeyCode: UInt32
    private var toggleMods: UInt32

    // 'FOZN' — unique 4-byte signature for Focus Zone hotkeys
    private let kSignature: OSType = 0x464F5A4E

    init() {
        let prefs = Preferences.shared
        toggleKeyCode = UInt32(prefs.hotkeyKeyCode)
        toggleMods = HotkeyManager.carbonMods(NSEvent.ModifierFlags(rawValue: UInt(prefs.hotkeyModifiers)))
        _hotkeyManagerRef = self
    }

    // MARK: - Lifecycle

    func start() {
        installEventHandler()
        registerToggle()
        registerSelect()
    }

    func stop() {
        if let r = toggleHotKeyRef { UnregisterEventHotKey(r); toggleHotKeyRef = nil }
        if let r = selectHotKeyRef { UnregisterEventHotKey(r); selectHotKeyRef = nil }
        if let r = eventHandlerRef { RemoveEventHandler(r); eventHandlerRef = nil }
    }

    func updateHotkey(keyCode: UInt16, modifiers: NSEvent.ModifierFlags) {
        toggleKeyCode = UInt32(keyCode)
        toggleMods = HotkeyManager.carbonMods(modifiers)
        guard eventHandlerRef != nil else { return }
        if let r = toggleHotKeyRef { UnregisterEventHotKey(r); toggleHotKeyRef = nil }
        registerToggle()
    }

    // MARK: - Private

    private func installEventHandler() {
        guard eventHandlerRef == nil else { return }

        var spec = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        // @convention(c) closure: cannot capture self, but can access the
        // module-level _hotkeyManagerRef global.
        let proc: EventHandlerProcPtr = { _, event, _ -> OSStatus in
            var hkID = EventHotKeyID()
            GetEventParameter(
                event,
                UInt32(kEventParamDirectObject),
                UInt32(typeEventHotKeyID),
                nil,
                MemoryLayout<EventHotKeyID>.size,
                nil,
                &hkID
            )
            DispatchQueue.main.async {
                switch hkID.id {
                case 1: _hotkeyManagerRef?.onTogglePressed?()
                case 2: _hotkeyManagerRef?.onSelectPressed?()
                default: break
                }
            }
            return noErr
        }

        // InstallApplicationEventHandler is a C macro; call the underlying function directly.
        InstallEventHandler(GetApplicationEventTarget(), proc, 1, &spec, nil, &eventHandlerRef)
    }

    private func registerToggle() {
        let hkID = EventHotKeyID(signature: kSignature, id: 1)
        RegisterEventHotKey(toggleKeyCode, toggleMods, hkID,
                            GetApplicationEventTarget(), 0, &toggleHotKeyRef)
    }

    private func registerSelect() {
        let hkID = EventHotKeyID(signature: kSignature, id: 2)
        let mods = UInt32(cmdKey | shiftKey)
        RegisterEventHotKey(UInt32(kVK_ANSI_S), mods, hkID,
                            GetApplicationEventTarget(), 0, &selectHotKeyRef)
    }

    private static func carbonMods(_ flags: NSEvent.ModifierFlags) -> UInt32 {
        var m: UInt32 = 0
        if flags.contains(.command) { m |= UInt32(cmdKey) }
        if flags.contains(.shift)   { m |= UInt32(shiftKey) }
        if flags.contains(.option)  { m |= UInt32(optionKey) }
        if flags.contains(.control) { m |= UInt32(controlKey) }
        return m
    }
}
