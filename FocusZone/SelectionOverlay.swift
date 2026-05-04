import AppKit

// MARK: - Window

/// A full-screen window that temporarily takes over the screen so the user can
/// drag a rectangle to define their focus region.
/// Level is .modalPanel so it sits above the .floating overlay windows.
final class SelectionOverlayWindow: NSWindow {
    var onRegionSelected: ((CGRect) -> Void)?
    var onCancelled: (() -> Void)?

    private let selectionView: SelectionOverlayView

    init(screen: NSScreen) {
        selectionView = SelectionOverlayView(frame: NSRect(origin: .zero, size: screen.frame.size))
        super.init(
            contentRect: screen.frame,
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )

        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        animationBehavior = .none
        level = .modalPanel   // above .floating
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        contentView = selectionView

        selectionView.onRegionSelected = { [weak self] rect in
            guard let self else { return }
            // Convert view-local rect → screen coordinates
            let screenRect = self.convertToScreen(rect)
            self.onRegionSelected?(screenRect)
            self.orderOut(nil)
        }
        selectionView.onCancelled = { [weak self] in
            self?.onCancelled?()
            self?.orderOut(nil)
        }
    }

    override var canBecomeKey: Bool { true }   // needed to receive key events (Escape)
    override var canBecomeMain: Bool { false }
}

// MARK: - View

/// Handles the drag interaction for drawing a focus rectangle.
/// Draws a dark semi-transparent background with a "hole" cutout showing the selection.
final class SelectionOverlayView: NSView {
    var onRegionSelected: ((NSRect) -> Void)?
    var onCancelled: (() -> Void)?

    private var startPoint: NSPoint?
    private var selectionRect: NSRect = .zero
    private var isDrawing = false

    // MARK: - Drawing

    override func draw(_ dirtyRect: NSRect) {
        guard let ctx = NSGraphicsContext.current?.cgContext else { return }

        // Dark background — slightly lighter than the main dim so users can see content
        NSColor.black.withAlphaComponent(0.55).setFill()
        NSBezierPath.fill(bounds)

        if isDrawing && selectionRect.width > 2 && selectionRect.height > 2 {
            // Punch a transparent hole for the selection area
            ctx.clear(selectionRect)

            // Dashed white border around the selection
            let border = NSBezierPath(rect: selectionRect.insetBy(dx: 1, dy: 1))
            border.lineWidth = 2
            border.setLineDash([6, 3], count: 2, phase: 0)
            NSColor.white.withAlphaComponent(0.9).setStroke()
            border.stroke()

            // Size label below the selection rectangle
            drawSizeLabel(for: selectionRect)
        }

        // Instruction hint when not drawing
        if !isDrawing {
            drawHint()
        }
    }

    private func drawSizeLabel(for rect: NSRect) {
        let label = "\(Int(rect.width)) × \(Int(rect.height))"
        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedSystemFont(ofSize: 12, weight: .medium),
            .foregroundColor: NSColor.white,
        ]
        let size = (label as NSString).size(withAttributes: attrs)
        var labelOrigin = NSPoint(
            x: rect.midX - size.width / 2,
            y: rect.minY - size.height - 6
        )
        // Flip above if too close to the bottom edge
        if labelOrigin.y < 4 {
            labelOrigin.y = rect.maxY + 6
        }
        let labelRect = NSRect(origin: labelOrigin, size: size)
        (label as NSString).draw(in: labelRect, withAttributes: attrs)
    }

    private func drawHint() {
        let text = "拖拽绘制聚焦区域   ·   Esc 取消"
        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 15, weight: .medium),
            .foregroundColor: NSColor.white.withAlphaComponent(0.85),
        ]
        let size = (text as NSString).size(withAttributes: attrs)
        let rect = NSRect(
            x: bounds.midX - size.width / 2,
            y: bounds.midY - size.height / 2,
            width: size.width,
            height: size.height
        )
        (text as NSString).draw(in: rect, withAttributes: attrs)
    }

    // MARK: - Mouse events

    override func mouseDown(with event: NSEvent) {
        startPoint = convert(event.locationInWindow, from: nil)
        selectionRect = .zero
        isDrawing = true
        needsDisplay = true
    }

    override func mouseDragged(with event: NSEvent) {
        guard let start = startPoint else { return }
        let current = convert(event.locationInWindow, from: nil)
        selectionRect = NSRect(
            x: min(start.x, current.x),
            y: min(start.y, current.y),
            width: abs(current.x - start.x),
            height: abs(current.y - start.y)
        )
        needsDisplay = true
    }

    override func mouseUp(with event: NSEvent) {
        guard isDrawing else { return }
        isDrawing = false

        if selectionRect.width > 20 && selectionRect.height > 20 {
            onRegionSelected?(selectionRect)
        } else {
            // Too small — treat as cancel
            selectionRect = .zero
            onCancelled?()
        }
        needsDisplay = true
    }

    // MARK: - Keyboard events

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 { // Escape
            isDrawing = false
            startPoint = nil
            selectionRect = .zero
            onCancelled?()
            needsDisplay = true
        }
    }

    override var acceptsFirstResponder: Bool { true }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        window?.makeFirstResponder(self)
    }
}
