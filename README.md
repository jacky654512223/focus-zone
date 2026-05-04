# Focus Zone

A lightweight macOS menu bar app that dims everything outside your selected focus area, helping you stay on task while reading, writing, or working.

## How It Works

You draw a rectangle on your screen — everything outside it gets dimmed. The focus area stays at full brightness. Mouse clicks and scrolling inside the focus area work normally. Press a shortcut to reselect your zone at any time.

## Features

- **Custom focus region** — drag to define exactly where you want to focus
- **Adjustable dim intensity** — 0–100%, dial it to your preference
- **Adjustable blur** — optional background blur behind the dim overlay
- **Keyboard shortcuts** — toggle dimming and reselect region without touching the mouse
- **Persistent across restarts** — your last region is remembered
- **Menu bar only** — no Dock icon clutter
- **Zero CPU at idle** — event-driven, not polling

## Requirements

- macOS 13.0 (Ventura) or later
- Apple Silicon or Intel Mac

## Usage

| Action | How |
|--------|-----|
| Select focus region | Click menu bar icon → **Select Focus Region**, then drag |
| Reselect region | `⌘⇧S` |
| Toggle dim on/off | `⌘⇧D` (configurable) |
| Adjust dim/blur | Click menu bar icon → sliders |

## Download

Download the latest `.dmg` from the [Releases](../../releases) page. Open it, drag **Focus Zone** to your Applications folder, and launch.

> **Note:** On first launch, macOS may show a security prompt. Go to **System Settings → Privacy & Security** and click **Open Anyway**.

## License

MIT License — see [LICENSE](LICENSE) for details.
