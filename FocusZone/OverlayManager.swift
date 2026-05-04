import AppKit

/// Manages four floating overlay windows arranged around a user-defined focus region.
///
/// Instead of a single full-screen window with a mask cutout, four OverlayWindows
/// are positioned above/below/left/right of the focus rectangle. The gap between
/// them is the focus area — no masking required, mouse events pass through naturally.
///
///   ┌──────────────────────────────────┐
///   │           TOP overlay            │
///   ├──────┬──────────────────┬────────┤
///   │      │                  │        │
///   │ LEFT │   focus hole     │ RIGHT  │
///   │      │  (uncovered)     │        │
///   ├──────┴──────────────────┴────────┤
///   │          BOTTOM overlay          │
///   └──────────────────────────────────┘
final class OverlayManager {
    // top, bottom, left, right
    private var overlayWindows: [OverlayWindow] = []
    private var isVisible = false
    private var focusRegion: CGRect = .zero

    deinit { tearDown() }

    // MARK: - Show / Hide

    func showOverlays() {
        isVisible = true
        if overlayWindows.isEmpty { createOverlays() }
        layoutOverlays()
    }

    func hideOverlays() {
        isVisible = false
        for window in overlayWindows { window.orderOut(nil) }
    }

    // MARK: - Focus region

    func updateFocusRegion(_ rect: CGRect) {
        focusRegion = rect
        if isVisible { layoutOverlays() }
    }

    // MARK: - Update blur / dim

    func updateBlur(_ radius: Double) {
        for w in overlayWindows { w.overlayView?.setBlurRadius(radius) }
    }

    func updateDim(_ opacity: Double) {
        for w in overlayWindows { w.overlayView?.setDimOpacity(opacity) }
    }

    // MARK: - Private

    private func createOverlays() {
        guard let screen = NSScreen.main else { return }

        // Use a placeholder 1x1 frame; layoutOverlays() will resize immediately
        for _ in 0..<4 {
            let window = OverlayWindow(frame: NSRect(x: 0, y: 0, width: 1, height: 1))
            overlayWindows.append(window)
        }

        // Use saved region or default to centre 60% of screen
        if focusRegion.isEmpty {
            let sf = screen.frame
            let w = sf.width * 0.6
            let h = sf.height * 0.6
            focusRegion = CGRect(
                x: sf.midX - w / 2,
                y: sf.midY - h / 2,
                width: w,
                height: h
            )
        }
    }

    private func layoutOverlays() {
        guard overlayWindows.count == 4,
              let screen = NSScreen.main else { return }

        let sf = screen.frame   // screen frame in global screen coordinates
        let r  = focusRegion

        let frames: [NSRect] = [
            // top: full width, from focus top to screen top
            NSRect(x: sf.minX, y: r.maxY,  width: sf.width, height: sf.maxY - r.maxY),
            // bottom: full width, from screen bottom to focus bottom
            NSRect(x: sf.minX, y: sf.minY, width: sf.width, height: r.minY - sf.minY),
            // left: focus height, from screen left to focus left
            NSRect(x: sf.minX, y: r.minY,  width: r.minX - sf.minX, height: r.height),
            // right: focus height, from focus right to screen right
            NSRect(x: r.maxX,  y: r.minY,  width: sf.maxX - r.maxX, height: r.height),
        ]

        for (window, frame) in zip(overlayWindows, frames) {
            if frame.width <= 0 || frame.height <= 0 {
                window.orderOut(nil)
            } else {
                window.setFrame(frame, display: true)
                window.orderFrontRegardless()
            }
        }
    }

    private func tearDown() {
        for window in overlayWindows { window.orderOut(nil) }
        overlayWindows.removeAll()
    }
}
