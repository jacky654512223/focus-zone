import AppKit

/// Simple overlay view: blur + dim. No cutout logic — the cutout is achieved
/// by positioning four of these windows AROUND the active window so they
/// never cover it at all.
final class OverlayView: NSView {
    private let blurView = NSVisualEffectView()
    private let dimView = NSView()

    override init(frame: NSRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        wantsLayer = true

        // Blur: GPU-composited by WindowServer via NSVisualEffectView
        blurView.material = .fullScreenUI
        blurView.blendingMode = .behindWindow
        blurView.state = .active
        blurView.frame = bounds
        blurView.autoresizingMask = [.width, .height]
        blurView.alphaValue = CGFloat(Preferences.shared.blurRadius / 30.0)
        addSubview(blurView)

        // Dim: semi-transparent black layer on top of blur
        dimView.wantsLayer = true
        dimView.layer?.backgroundColor = NSColor.black.withAlphaComponent(Preferences.shared.dimOpacity).cgColor
        dimView.frame = bounds
        dimView.autoresizingMask = [.width, .height]
        addSubview(dimView)
    }

    func setBlurRadius(_ radius: Double) {
        blurView.alphaValue = CGFloat(max(min(radius / 30.0, 1.0), 0.0))
    }

    func setDimOpacity(_ opacity: Double) {
        dimView.layer?.backgroundColor = NSColor.black.withAlphaComponent(opacity).cgColor
    }
}
