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

---

## Lockscreen Module (`qs.features.lockscreen`)

### Architecture
- Uses `WlSessionLock` (Quickshell 0.3.0+) for proper session locking via `ext-session-lock-v1`
- `WlSessionLockSurface` is a **QWindow**, not a QQuickItem — `Keys` and `focus` properties don't work on it directly
- Use a child `FocusScope` or `MouseArea` to capture input
- Authentication via `PamContext` with custom PAM config at `features/lockscreen/pam.d/quickshell`

### PAM Flow
1. User types password → presses Enter
2. Store password in `_pendingPassword`, clear input field
3. Call `pamContext.start()` to begin authentication
4. When `responseRequired` changes to true, call `pamContext.respond(_pendingPassword)`
5. On `PamResult.Success` → emit unlock signal, on failure → shake animation + error message

### IPC Usage
```bash
quickshell ipc call lock lockSession    # Lock
quickshell ipc call lock unlockSession  # Unlock (testing)
quickshell ipc call lock isLocked       # Check status
```

### Niri Keybind
```kdl
bind SUPER+Escape { spawn "quickshell ipc call lock lockSession"; }
```

### Important Gotchas
- `WlSessionLockSurface` cannot use `Keys.onPressed` directly — use a child `FocusScope` or `MouseArea`
- `forceActiveFocus()` on `WlSessionLockSurface` will crash — use it on child `TextInput` instead
- Content must start visible (opacity 1) when the surface is created, otherwise you get a black screen
- Use a delayed timer (`lockAnimTimer`) to trigger the fade-in animation after surface creation

---

## Quickshell Plugin System (Caelestia Blobs)

### How It's Compiled
Build system: CMake + Qt6's QML module system

```cmake
# plugins/CMakeLists.txt
qt_add_qml_module(caelestia-blobs
    URI Caelestia.Blobs
    VERSION 1.0
    SOURCES
        Caelestia/Blobs/blobgroup.hpp
        Caelestia/Blobs/blobgroup.cpp
        # ... more sources
)
qt_add_shaders(caelestia-blobs "blob_shaders"
    BATCHABLE OPTIMIZED NOHLSL NOMSL
    GLSL "300es,330"
    PREFIX "/"
    FILES
        Caelestia/Blobs/shaders/blob.frag
        Caelestia/Blobs/shaders/blob.vert
)
```

Build command:
```bash
cd ~/.config/quickshell/plugins/build
cmake .. -DCMAKE_PREFIX_PATH=$(pkg-config --variable=prefix Qt6Core)
make
```

Quickshell automatically loads compiled QML modules from the `build/` directory.

### Architecture
| Component | Role |
|---|---|
| `BlobGroup` | Manages shapes, holds `color` + `smoothing` |
| `BlobShape` | Base `QQuickItem` with custom `updatePaintNode()` |
| `BlobRect` | Rectangle with spring physics for deformation |
| `BlobInvertedRect` | Creates a "hole" (frame) in the blob |
| `BlobMaterial` | `QSGMaterial` that packs rect data into uniforms |
| `blob.frag` | GLSL shader using SDF merging (`smin`) |

The shader uses signed distance functions to merge multiple rectangles into a single smooth blob. `smoothing` controls the blend radius.

### Creating a Custom Plugin
1. Create directory structure:
```
plugins/MyPlugin/
├── CMakeLists.txt
├── MyPlugin/
│   ├── MyComponent.hpp
│   └── MyComponent.cpp
```

2. Use `QML_ELEMENT` macro in C++ to expose types to QML
3. Build with CMake, Quickshell loads from `build/` automatically

---

## Matugen Cache System

### Location
`~/.config/quickshell/scripts/matugen-cache.sh`

### How It Works
- Caches all matugen-generated theme files per wallpaper in `~/.config/quickshell/common/.matugen_cache/`
- Nested structure: `.matugen_cache/<scheme-type>/<mode>/<wallpaper.jpg>/`
- On wallpaper change, checks cache first — if exists, applies cached files instantly
- If no cache, runs matugen to generate, then caches all outputs

### Post-Hooks
After applying cached files, runs reload signals for:
- Gradience (GTK4/libadwaita)
- GTK theme toggle
- Kitty (SIGUSR1 + socket reload)

### Zen Browser
**Removed from matugen-cache.sh.** The zen browser template and chrome directory touch were removed to avoid conflicts with transparent-zen. If you need zen theming back, re-add it to:
- `CACHE_FILES` array in `matugen-cache.sh`
- `run_post_hooks()` function
- `~/.config/matugen/config.toml` (uncomment `[templates.zen]`)

---

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
