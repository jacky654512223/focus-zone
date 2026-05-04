import AppKit

/// A borderless, transparent, click-through overlay window.
/// Positioned at .floating level so it sits above all normal app windows.
/// Four of these are arranged around the focus region to create a "hole"
/// without any masking — the uncovered gap is the focus area.
final class OverlayWindow: NSWindow {
    convenience init(frame: NSRect) {
        self.init(
            contentRect: frame,
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )

        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        ignoresMouseEvents = true
        animationBehavior = .none

        // Floating level — sits above all normal (.normal level) app windows.
        level = .floating

        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]

        let overlayView = OverlayView(frame: NSRect(origin: .zero, size: frame.size))
        contentView = overlayView
    }

    // Prevent this window from ever becoming key or main
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }

    var overlayView: OverlayView? {
        contentView as? OverlayView
    }
}
