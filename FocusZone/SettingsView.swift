import SwiftUI
import Combine

/// SwiftUI popover shown when the user clicks the menu bar icon.
struct SettingsView: View {
    @ObservedObject private var prefs = Preferences.shared
    @State private var isRecordingHotkey = false
    @State private var hotkeyMonitor: Any?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text("Focus Zone")
                    .font(.headline)
                Spacer()
                Toggle("", isOn: $prefs.isEnabled)
                    .toggleStyle(.switch)
                    .labelsHidden()
            }

            Divider()

            // Region selection
            Group {
                Button(action: enterSelectionMode) {
                    HStack(spacing: 6) {
                        Image(systemName: "rectangle.dashed")
                        Text("Select Focus Region")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)

                Text("⌘⇧S to reselect at any time")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Divider()

            // Dim and blur sliders
            Group {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Dim: \(Int(prefs.dimOpacity * 100))%")
                        .font(.subheadline)
                    Slider(value: $prefs.dimOpacity, in: 0...1, step: 0.01)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Blur: \(Int(prefs.blurRadius))")
                        .font(.subheadline)
                    Slider(value: $prefs.blurRadius, in: 0...30, step: 1)
                }
            }

            Divider()

            // Hotkey and system settings
            Group {
                HStack {
                    Toggle("Shortcut (toggle dim)", isOn: $prefs.hotkeyEnabled)
                        .font(.subheadline)
                    Spacer()
                    Button(action: { startRecording() }) {
                        Text(isRecordingHotkey ? "Press keys…" : prefs.hotkeyLabel)
                            .font(.subheadline.monospaced())
                            .foregroundColor(isRecordingHotkey ? .accentColor : .secondary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(isRecordingHotkey ? Color.accentColor.opacity(0.15) : Color.secondary.opacity(0.15))
                            .cornerRadius(4)
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(isRecordingHotkey ? Color.accentColor : Color.clear, lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                }

                Toggle("Launch at login", isOn: $prefs.launchAtLogin)
                    .font(.subheadline)
                    .onChange(of: prefs.launchAtLogin) { newValue in
                        LoginItemManager.setEnabled(newValue)
                    }
            }

            Divider()

            Button("Quit Focus Zone") {
                NSApplication.shared.terminate(nil)
            }
            .font(.subheadline)
        }
        .padding(16)
        .frame(width: 280)
        .onDisappear {
            stopRecording()
        }
    }

    // MARK: - Actions

    private func enterSelectionMode() {
        if let delegate = NSApplication.shared.delegate as? AppDelegate {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                delegate.enterSelectionMode()
            }
        }
    }

    // MARK: - Hotkey recording

    private func startRecording() {
        guard !isRecordingHotkey else { return }
        isRecordingHotkey = true

        hotkeyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            let mods = event.modifierFlags.intersection(.deviceIndependentFlagsMask)

            if event.keyCode == 53 { // Escape
                stopRecording()
                return nil
            }

            let hasModifier = !mods.intersection([.command, .option, .control, .shift]).isEmpty
            guard hasModifier else { return nil }

            let character = event.charactersIgnoringModifiers ?? ""
            prefs.hotkeyKeyCode   = Int(event.keyCode)
            prefs.hotkeyModifiers = Int(mods.rawValue)
            prefs.hotkeyCharacter = character

            stopRecording()
            return nil
        }
    }

    private func stopRecording() {
        isRecordingHotkey = false
        if let monitor = hotkeyMonitor {
            NSEvent.removeMonitor(monitor)
            hotkeyMonitor = nil
        }
    }
}
