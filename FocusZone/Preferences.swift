import AppKit
import Carbon.HIToolbox
import Combine

/// Central settings store backed by UserDefaults.
/// Published properties drive live UI updates and overlay changes.
final class Preferences: ObservableObject {
    static let shared = Preferences()

    private enum Keys {
        static let isEnabled       = "isEnabled"
        static let blurRadius      = "blurRadius"
        static let dimOpacity      = "dimOpacity"
        static let hotkeyEnabled   = "hotkeyEnabled"
        static let hotkeyKeyCode   = "hotkeyKeyCode"
        static let hotkeyModifiers = "hotkeyModifiers"
        static let hotkeyCharacter = "hotkeyCharacter"
        static let launchAtLogin   = "launchAtLogin"
        static let focusRegion     = "focusRegion"
    }

    @Published var isEnabled: Bool {
        didSet { UserDefaults.standard.set(isEnabled, forKey: Keys.isEnabled) }
    }

    @Published var blurRadius: Double {
        didSet { UserDefaults.standard.set(blurRadius, forKey: Keys.blurRadius) }
    }

    /// Dim opacity as a fraction 0.0–1.0 (UI shows 0–100%)
    @Published var dimOpacity: Double {
        didSet { UserDefaults.standard.set(dimOpacity, forKey: Keys.dimOpacity) }
    }

    @Published var hotkeyEnabled: Bool {
        didSet { UserDefaults.standard.set(hotkeyEnabled, forKey: Keys.hotkeyEnabled) }
    }

    @Published var hotkeyKeyCode: Int {
        didSet { UserDefaults.standard.set(hotkeyKeyCode, forKey: Keys.hotkeyKeyCode) }
    }

    @Published var hotkeyModifiers: Int {
        didSet { UserDefaults.standard.set(hotkeyModifiers, forKey: Keys.hotkeyModifiers) }
    }

    @Published var hotkeyCharacter: String {
        didSet { UserDefaults.standard.set(hotkeyCharacter, forKey: Keys.hotkeyCharacter) }
    }

    /// Human-readable label for the current hotkey (e.g. "⌘⇧D").
    var hotkeyLabel: String {
        var label = ""
        let mods = NSEvent.ModifierFlags(rawValue: UInt(hotkeyModifiers))
        if mods.contains(.control) { label += "⌃" }
        if mods.contains(.option)  { label += "⌥" }
        if mods.contains(.shift)   { label += "⇧" }
        if mods.contains(.command) { label += "⌘" }
        label += hotkeyCharacter.uppercased()
        return label
    }

    @Published var launchAtLogin: Bool {
        didSet { UserDefaults.standard.set(launchAtLogin, forKey: Keys.launchAtLogin) }
    }

    /// The user-defined focus region in screen coordinates.
    /// Stored as a plain dictionary so UserDefaults can persist it.
    var focusRegion: CGRect? {
        get {
            guard let d = UserDefaults.standard.dictionary(forKey: Keys.focusRegion),
                  let x = d["x"] as? Double, let y = d["y"] as? Double,
                  let w = d["w"] as? Double, let h = d["h"] as? Double
            else { return nil }
            return CGRect(x: x, y: y, width: w, height: h)
        }
        set {
            if let r = newValue {
                UserDefaults.standard.set(
                    ["x": r.origin.x, "y": r.origin.y, "w": r.width, "h": r.height],
                    forKey: Keys.focusRegion
                )
            } else {
                UserDefaults.standard.removeObject(forKey: Keys.focusRegion)
            }
        }
    }

    private init() {
        let defaults = UserDefaults.standard

        defaults.register(defaults: [
            Keys.isEnabled:       true,
            Keys.blurRadius:      10.0,
            Keys.dimOpacity:      0.6,
            Keys.hotkeyEnabled:   true,
            Keys.hotkeyKeyCode:   kVK_ANSI_D,
            Keys.hotkeyModifiers: Int(NSEvent.ModifierFlags([.command, .shift]).rawValue),
            Keys.hotkeyCharacter: "D",
            Keys.launchAtLogin:   false,
        ])

        self.isEnabled       = defaults.bool(forKey: Keys.isEnabled)
        self.blurRadius      = defaults.double(forKey: Keys.blurRadius)
        self.dimOpacity      = defaults.double(forKey: Keys.dimOpacity)
        self.hotkeyEnabled   = defaults.bool(forKey: Keys.hotkeyEnabled)
        self.hotkeyKeyCode   = defaults.integer(forKey: Keys.hotkeyKeyCode)
        self.hotkeyModifiers = defaults.integer(forKey: Keys.hotkeyModifiers)
        self.hotkeyCharacter = defaults.string(forKey: Keys.hotkeyCharacter) ?? "D"
        self.launchAtLogin   = defaults.bool(forKey: Keys.launchAtLogin)
    }
}
