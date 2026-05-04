import AppKit
import SwiftUI
import Combine

/// Manages the menu bar status item and its popover.
final class StatusBarController {
    private var statusItem: NSStatusItem
    private var popover: NSPopover
    private var cancellable: AnyCancellable?

    init() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        popover = NSPopover()
        popover.contentSize = NSSize(width: 260, height: 300)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: SettingsView())

        updateIcon(enabled: Preferences.shared.isEnabled)

        if let button = statusItem.button {
            button.action = #selector(togglePopover(_:))
            button.target = self
        }

        // Update icon when enabled state changes
        cancellable = Preferences.shared.$isEnabled
            .sink { [weak self] enabled in
                self?.updateIcon(enabled: enabled)
            }
    }

    private func updateIcon(enabled: Bool) {
        let symbolName = enabled ? "eye.slash" : "eye"
        statusItem.button?.image = NSImage(systemSymbolName: symbolName, accessibilityDescription: "Focus Zone")
    }

    @objc private func togglePopover(_ sender: AnyObject?) {
        guard let button = statusItem.button else { return }
        if popover.isShown {
            popover.performClose(sender)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            // Ensure the popover's window becomes key so clicks outside dismiss it
            popover.contentViewController?.view.window?.makeKey()
        }
    }
}
