# Agents.md - Project Documentation

## Working Directory (Stow)

**All work must be done in `/home/httpkiwi/niri/`.** This is a GNU Stow dotfiles repo. Files are under `.config/` and symlinked to `~/.config/` via stow. Never edit files directly under `~/.config/` — always edit them in the repo at `/home/httpkiwi/niri/`.

Session-specific resume notes (dirty tree, unfinished UX): see [`HANDOFF.md`](./HANDOFF.md).

## Important Commands

### Never Kill Niri
**NEVER run `killall niri` or similar commands.** Niri manages the entire desktop session - killing it will terminate your GUI. If issues occur, let Quickshell auto-reload by saving a QML file.

### Niri Config Changes
When modifying niri config in the repo (`.config/niri/config.kdl`), always validate:
```bash
niri validate
```

### Quickshell Config Changes
When modifying Quickshell QML files, the shell auto-reloads when files change. Do NOT manually restart Quickshell:
- Quickshell watches `~/.config/quickshell/` (stow → this repo) for changes and auto-reloads
- Check `qs log` after QML changes to catch runtime errors
- If there are errors, save a QML file to trigger a reload

### Other useful checks
```bash
qs log
qs ipc call lock isLocked
qs ipc call caffeine isEnabled
python3 ~/Projects/Kiwiboard/zmk-split-battery-tray/host/zmk-split-battery.py --json --timeout 1.0 --retries 4 --swap
```

---

## Project Overview

Custom desktop environment:
- **Niri** — Wayland compositor
- **Quickshell** — QML shell (`UnifiedBar` + `PocketFrame` blob chrome)
- **Matugen** — Material color generation from wallpaper
- **Kiwiboard** — ZMK split keyboard (USB dongle central + L/R peripherals); host tooling lives outside this repo

---

## Code Style Guidelines

### File Organization

**Imports Order:**
1. QtQuick modules (`QtQuick`, `QtQuick.Controls`, `QtQuick.Layouts`)
2. Quickshell modules (`Quickshell`, `Quickshell.Io`, `Quickshell.Wayland`)
3. Local config imports (`qs.config`)
4. Local core imports (`qs.core`)
5. Local component imports (`qs.components.base`, `qs.features.*`)

```qml
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.config
import qs.core
import qs.components.base
import qs.features.launcher
```

**Pragmas:**
- Use `pragma Singleton` for singleton objects (Settings, Theme, Color)
- Use `pragma ComponentBehavior: Bound` for better component lifecycle management

### Naming Conventions

| Element | Convention | Example |
|---------|------------|---------|
| Files | PascalCase | `AppLauncher.qml`, `NotificationManager.qml` |
| QML Types | PascalCase | `PanelWindow`, `ListView`, `ListModel` |
| Properties | camelCase | `visible`, `selectedIndex`, `searchText` |
| Functions | camelCase | `loadAppsIfNeeded()`, `updateFilter()` |
| Constants | camelCase | `animationDurationShort`, `maxVisibleItems` |
| Signal Handlers | camelCase | `onVisibleChanged`, `onTextChanged` |
| IDs | camelCase | `id: appLauncher`, `id: searchInput` |
| Enums/Constants | PascalCase | `Qt.Key_Escape`, `ListView.Contain` |

### Property Definitions

**Use `readonly property` for constants:**
```qml
readonly property int maxVisibleItems: 5
readonly property int animationDurationShort: 150
readonly property string fontFamilyDefault: "sans-serif"
```

**Use `property` for mutable state:**
```qml
property int selectedIndex: 0
property bool _isHiding: false
property var filteredApps: []
```

### Component Structure

**QtObject (Non-visual singletons):**
```qml
pragma Singleton
pragma ComponentBehavior: Bound

QtObject {
    id: root

    function myFunction() {
        // Implementation
    }

    Component.onCompleted: {
        console.log("Component initialized")
    }
}
```

**Visual Components:**
```qml
PanelWindow {
    id: root

    property var allApps: []
    property int selectedIndex: 0
    readonly property int itemHeight: 40

    function loadData() {
        // Implementation
    }

    Component.onCompleted: {
        // Initialization
    }

    // UI elements
    Item {
        // ...
    }
}
```

### Documentation

**Use JSDoc-style comments for top-level documentation:**
```qml
/**
 * AppLauncherSource - Launcher source for desktop applications
 * See ClipboardLauncherSource.qml for another reference implementation.
 */
QtObject {
    // ...
}
```

**Use single-line comments for inline explanations:**
```qml
// Lazy-load desktop entries only when needed
if (allApps.length === 0) {
    // ...
}
```

### Error Handling

**Use console.log/warn/error for logging:**
```qml
console.log("Color: Component completed, loading initial colors")
console.warn("Failed to load app:", error)
console.error("Invalid state:", details)
```

**Use defensive coding:**
```qml
function executeSelected() {
    if (filteredItems.length === 0) return;

    if (selectedIndex >= 0 && selectedIndex < filteredItems.length) {
        const item = filteredItems[selectedIndex];
        if (item && item.execute) {
            item.execute();
        }
    }
}
```

### UI Patterns

**Use declarative property bindings:**
```qml
readonly property int listContentHeight: Math.min(filteredModel.count, maxVisibleItems) * itemHeight

height: animatedHeight

Behavior on height {
    enabled: launcher.visible
    NumberAnimation {
        duration: Settings.animationDurationShort
        easing.type: Easing.OutQuad
    }
}
```

**Use proper anchor/margin patterns:**
```qml
anchors {
    top: parent.top
    topMargin: verticalSpacing
    left: parent.left
    right: parent.right
    bottom: parent.bottom
}
```

### Animations

- Use `Behavior` for simple property animations
- Use `NumberAnimation` with `duration` and `easing.type`
- Use `SequentialAnimation` for multi-step animations
- Keep durations consistent: `Settings.animationDurationShort` (150ms), `animationDurationMedium` (250ms)

---

## Panel State

Per-monitor flags in `PanelState` (via `PanelStates.forName(Niri.focused_output_name)`):

| Flag | Pocket / UI |
|------|-------------|
| `launcher` | Bottom launcher (+ optional `clipboard` mode) |
| `wallpaper` | Bottom wallpaper selector |
| `controlCenter` | Right slide control center |
| `osd` | Left slide volume OSD |
| `settings` | Settings panel |
| `calendar` | Calendar pocket from date/time pills |

Mutex rules: launcher ↔ wallpaper; settings/calendar close each other and major panels as coded in `PanelState.qml`.

---

## IPC Handlers (`shell.qml`)

| Target | Functions | Typical bind |
|--------|-----------|--------------|
| `appLauncher` | `toggleLauncher`, `toggleClipboard` | `Super+Space`, `Super+V` |
| `controlCenter` | `toggleControlCenter` | `Super+N` |
| `wallpaperSelector` | `toggleSelector` | `Super+Shift+W` |
| `settings` | `toggle`, `open`, `close`, `isOpen` | (settings UI / bind) |
| `audio` | `raiseVolume`, `lowerVolume`, `toggleMute`, `toggleMicMute` | Prefer these over raw `wpctl` so OSD tracks |
| `screenrecord` | `toggle`, `start`, `stop`, `pause`, `isRecording` | Control center / bind |
| `caffeine` | `toggle`, `enable`, `disable`, `isEnabled` | Idle inhibit |
| `notifications` | `dismissFocused`, `focusPopup`, `navigateUp/Down`, `activateFocused` | Keyboard notif nav |
| `storage` | `clearAll` | — |
| `lock` | `lockSession`, `unlockSession`, `isLocked` | `Mod+Escape` (in lockscreen module) |
| `mpris` | play/pause/next/… | (in `Players.qml`) |

---

## Pocket Panel Components

Bar pockets share animation bases in `components/base/`:

- **PocketSlidePanel** — horizontal slide (OSD from left, control center from right)
- **PocketBottomPanel** — bottom emerge (launcher, wallpaper)

Calendar and settings follow the same blob-mounted pocket patterns in `UnifiedBar` / `PocketFrame`. Bind `panelFlag` to the matching `PanelState` bool.

---

## Calendar Module (`qs.features.calendar`)

- **`CalendarPanel.qml`** — month view pocket; opened from bar **date** and **time** indicators
- **`ColombianHolidays.qml`** — Colombia public holidays + Ley Emiliani shifting
- Glass styling on cards (not a single solid panel fill); blob rect wired in `PocketFrame`
- Flag: `panelState.calendar`

---

## Settings Modules

- **`features/settings/ModulesPage.qml`** — toggles for bar modules (workspaces, title, volume, recording, headset, **keyboard battery**, resources, date/time)
- Prefs persist via `Settings.setPref` → `common/shell-prefs.json`
- Other pages: Appearance, Shell, Chrome, Niri, About

Bar visibility prefs (examples): `showBarWorkspaces`, `showBarKeyboardBattery`, `showBarDate`, `showBarTime`, …

---

## Keyboard Battery (ZMK / Kiwiboard)

Bar indicator: `components/indicators/KeyboardBatteryIndicator.qml`.

### Data path
1. Dongle exposes HID battery (firmware in `zmk-config`; central fetch + proxy)
2. Host script polls:  
   `/home/httpkiwi/Projects/Kiwiboard/zmk-split-battery-tray/host/zmk-split-battery.py`  
   Flags: `--json`, `--timeout`, `--retries`, **`--swap`**
3. QML `Process` + timer (~6s); keep last reading on `WAITING`

### Important: L/R are pairing slots
ZMK peripheral **slot 0/1 = BLE pairing order**, not physical left/right. If charging the right half moves the left %, enable swap.

| Pref | Default | Meaning |
|------|---------|---------|
| `showBarKeyboardBattery` | `true` | Show pill |
| `keyboardBatterySwapLR` | `true` | Pass `--swap` (correct for current pairing) |
| `keyboardBatteryLowThreshold` | `20` | Low warning threshold |

### UX intent
- **Calm default:** keyboard icon only (no constant dual %)
- **Hover:** full `L xx%  R yy%`
- **Low (≤ threshold):** icon blinks (`Theme.error`), show only the low side(s)
- Do not reflash firmware for UI/slot bugs; fix with `--swap` / prefs
- Cells are **~150 mAh**; ZMK profiler ~1–2 months is optimistic → ~**1 month** daily use is realistic. Jumpy % is SoC noise + slot mapping, not sudden failure

### Toggle location
**Settings → Modules →** Keyboard battery / Swap keyboard L/R

---

## Background System

`Background.qml` supports static images, **animated WebP/GIF/APNG**, and **video** wallpapers (gated by `Settings.animatedWallpapersEnabled` / focused-only prefs). `BackgroundUtil.qml` classifies media type. Matugen/lock use still posters for video.

---

## Development Notes

- Prefer editing repo paths; stow keeps `~/.config` in sync
- Niri must be restarted (or config reload if supported) to apply `config.kdl` — always `niri validate` first
- Use `MatugenPreferences` for color scheme preferences
- Wallpaper selection saves to `current_wallpaper.json` in the wallpapers directory
- `qs config` inspects Quickshell configuration
- Do not commit large built artifacts under `qml/Caelestia/Blobs/*.so` unless intentional
- Many absolute `/home/httpkiwi/` paths exist in Settings/scripts — keep consistent when changing machines


## Reference Implementations

Local references available at:
- `~/.references/niri-caelestia-shell/` — Caelestia shell for Niri
- `~/.references/caelestia-shell/` — Original Caelestia shell

Key modules to study:
- `modules/lock/` — Lockscreen with `WlSessionLock` + `PamContext`
- `modules/background/` — Background with `BackgroundEffect`
- `modules/bar/` — Bar implementation with blob effects

### end-4/dots-hyprland Lockscreen Pattern
- Desktop windows slide DOWN off-screen (Hyprland workspace animation)
- Lockscreen content: clock centered, bottom toolbar with username/password/power pills
- Toolbar fades in + scales up (0.9→1) on lock
- Toolbar scales down + fades out on unlock
- All pills are rounded rectangles with semi-transparent backgrounds

---

## Planned / known debt (short)

1. Verify keyboard-battery calm + low blink live (`qs log`)
2. Glass chrome: `blob.frag` × `color.a` → rebuild plugin → `chromeOpacity` → `PocketFrame` / blur
3. Prefer volume keys → `qs ipc call audio …` if OSD should always track
4. Legacy unused QML still present in places; prefer `UnifiedBar` / pocket paths as canonical
5. See `HANDOFF.md` for current dirty-tree resume order
