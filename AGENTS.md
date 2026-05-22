# Agents.md - Project Documentation

## Working Directory (Stow)

**All work must be done in `/home/httpkiwi/niri/`.** This is a GNU Stow dotfiles repo. Files are under `.config/` and symlinked to `~/.config/` via stow. Never edit files directly under `~/.config/` — always edit them in the repo at `/home/httpkiwi/niri/`.

## Important Commands

### Never Kill Niri
**NEVER run `killall niri` or similar commands.** Niri manages the entire desktop session - killing it will terminate your GUI. If issues occur, let Quickshell auto-reload by saving a QML file.

### Niri Config Changes
When modifying `~/.config/niri/config.kdl`, always validate before restarting:
```bash
niri validate
```

### Quickshell Config Changes
When modifying Quickshell QML files, the shell auto-reloads when files change. Do NOT manually restart Quickshell:
- Quickshell watches `~/.config/quickshell/` for changes and auto-reloads
- Check `qs log` after QML changes to catch runtime errors
- If there are errors, save a QML file to trigger a reload

---

## Project Overview

This is a custom desktop environment setup using:
- **Niri** - Wayland compositor
- **Quickshell** - QML-based shell framework
- **Matugen** - Material color generation tool

---

## Directory Structure

```
~/.config/
├── niri/                    # Niri compositor config
│   └── config.kdl          # Main Niri configuration
│
└── quickshell/             # Quickshell shell config
    ├── shell.qml           # Main entry point
    │
    ├── common/             # Shared resources
    │   ├── Colors.json     # Color palette
    │   └── Popup.qml       # Popup component
    │
    ├── config/             # Configuration files
    │   ├── Settings.qml    # Hardcoded values (durations, sizes, margins)
    │   ├── Theme.qml       # Semantic colors and styling
    │   └── MatugenPreferences.qml  # Matugen settings
    │
    ├── core/               # Core logic and services
    │   ├── LauncherSource.qml  # Base interface for launcher sources
    │   ├── Niri.qml        # Niri event stream integration
    │   ├── Color.qml       # Color utilities
    │   ├── Audio.qml       # Audio management
    │   ├── NotificationStore.qml    # Notification persistence
    │   ├── NotificationService.qml  # D-Bus notification handling
    │   ├── FuzzyMatcher.qml          # Search matching
    │   └── ResourceUsage.qml         # System resource monitoring
    │
    ├── components/         # Reusable UI components
    │   ├── base/           # Basic components (Card, Pill, IconButton, etc.)
    │   ├── animations/      # Animation components
    │   └── indicators/      # Indicator components
    │
    ├── features/           # Main UI features
    │   ├── bar/           # Top bar
    │   ├── background/    # Desktop background
    │   ├── wallpaper/     # Wallpaper selector
    │   ├── launcher/      # App launcher with clipboard support
    │   ├── notifications/ # Notification system
    │   ├── osd/          # On-screen display
    │   └── decorations/  # Window decorations
    │
    └── scripts/           # Helper scripts
```

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
 * LauncherSource - Base interface for launcher data sources
 * Implement this to create new launcher backends (apps, clipboard, gifs, etc.)
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

## Launcher Extension System

### Creating a New Launcher Source

1. Create `features/launcher/XXXLauncherSource.qml`
2. Extend `LauncherSource`:
```qml
import qs.core

LauncherSource {
    readonly property string sourceName: "mySource"
    readonly property string displayName: "My Source"

    function loadItems() { /* Load data */ }
    function filterItems(searchText) { /* Filter & sort */ }
    function getItemDisplay(item) { /* Return {icon, title, subtitle} */ }
    function executeItem(item) { /* Execute action */ }
    function getPrefix() { return ":"; }  // Optional prefix for quick switching
}
```

2. Add to `Launcher.qml` sources array:
```qml
property var sources: [appLauncherSource, clipboardLauncherSource, mySource]
```

---

## Background System

The background system supports:
- **Static images**: PNG, JPG, JPEG, BMP, SVG, TIFF
- **Animated images**: GIF, WebP, APNG
- **Videos**: MP4, WebM, MKV, MOV

Crossfade transition uses dual-layer system with 300ms `Easing.InOutQuad` animation.

---

## Development Notes

- Quickshell watches `~/.config/quickshell/` for changes and auto-reloads
- Niri must be restarted to apply config changes
- Always run `niri validate` after editing `config.kdl`
- Check `qs log` after QML changes to catch runtime errors
- Use `MatugenPreferences` singleton for color scheme preferences
- The wallpaper selector saves to `current_wallpaper.json` in the wallpapers directory
- Use `qs config` to inspect Quickshell configuration
