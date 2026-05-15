# Niri Desktop Shell - Handoff Document

## Current State Overview

Restructuring from separate PanelWindow popups to a **single-window architecture** where all panels live inside the UnifiedBar's PanelWindow as inline Items, with dedicated BlobRects in PocketFrame bound directly to each panel's geometry.

## What's Done

### Notifications ✅
- **NotificationModel** singleton in `core/` — shared ListModel for notification data
- **NotificationItem.qml** — Item-based notification (swipe, auto-dismiss, etc.)
- **NotificationManager.qml** — simplified, pushes to NotificationModel, no PopupRegistry
- **Wrapper** in UnifiedBar.qml — `notifWrapper` with ListView bound to NotificationModel
- **BlobRect** in PocketFrame — bound to `notifWrapper` (pure QML binding, no timing issues)
- **NotificationCard.qml** reused for styling (summary, body, app icon, image)

### Launcher In Progress 🟡
- **LauncherPanel.qml** created in `features/bar/` — inline launcher as Item
  - Contains search, app list, clipboard history, keyboard nav
  - Visibility controlled by `root.show` + `root.showAnimation`
  - Animations: height (0→calculatedHeight), opacity, y-translate
  - IPC target: centralized in `shell.qml` via `PopupRegistry.launcherPanels` map
  - Registered via `Component.onCompleted` → `PopupRegistry.launcherPanels[name] = root`
  - Functions exposed: `toggleLauncher()`, `toggleClipboard()`, `toggle()`
- **BlobRect** in PocketFrame — bound to `launcherPanel` (set via `pocketFrame.launcherPanel = launcherPanel`)
- **IpcHandler** removed from LauncherPanel, centralized in `shell.qml`
- **L button** in top bar (left of workspace indicators) for testing

### Volume OSD / Wallpaper / History 🟡 
- Not yet migrated. Still use old PanelWindow + PopupRegistry approach.

## Key Files

### New/Modified
| File | Purpose |
|------|---------|
| `core/NotificationModel.qml` | Singleton: shared notification ListModel |
| `core/PopupRegistry.qml` | Added `notifWrappers`, `launcherPanels` maps |
| `core/qmldir` | Added `NotificationModel` |
| `core/Niri.qml` | Added `niriNameFor()` helper |
| `features/bar/UnifiedBar.qml` | Main shell window: top bar, notifWrapper, LauncherPanel, PocketFrame refs |
| `features/bar/LauncherPanel.qml` | Inline launcher content (search, list, keyboard nav) |
| `features/bar/PocketFrame.qml` | Added `notifWrapper`, `launcherPanel` properties + dedicated BlobRects |
| `features/bar/qmldir` | Added `LauncherPanel` |
| `features/launcher/qmldir` | **New** — exports only AppLauncherSource, ClipboardLauncherSource |
| `features/notifications/NotificationManager.qml` | Simplified: pushes to NotificationModel |
| `features/notifications/NotificationItem.qml` | Item-based notification (vs old PanelWindow) |
| `shell.qml` | Centralized IpcHandlers; removed old Launcher import |

### Deleted
| File | Reason |
|------|--------|
| `features/launcher/AppLauncher.qml` | Contained conflicting IpcHandler("appLauncher") |
| `features/launcher/Launcher.qml` | Contained conflicting IpcHandler("appLauncher") |

### Still to migrate/clean up
| File | Plan |
|------|------|
| `features/osd/VolumeOSD.qml` → inline OSDPanel in UnifiedBar |
| `features/wallpaper/WallpaperSelector.qml` → inline WallpaperPanel |
| `features/notifications/NotificationHistoryPanel.qml` → inline |
| `features/notifications/NotificationPopup.qml` | No longer used (replaced by NotificationItem) |
| `core/PopupRegistry.qml` | Remove after all panels migrated |
| `core/qmldir` → remove PopupRegistry entry |

## Architecture

### Single Window Per Screen
```
UnifiedBar PanelWindow (per screen, via Variants)
├── topBar (Rect: workspaces, title, indicators)
├── notifWrapper (Item: ListView + NotificationModel)
├── LauncherPanel (Item: search + app list)
├── PocketFrame (Item: BlobGroup + BlobInvertedRect + BlobRects)
│   ├── BlobRect → notifWrapper (direct binding)
│   └── BlobRect → launcherPanel (direct binding)
└── mask: Region (XOR inner area, Subtract panel regions)
```

### Data Flow
```
NotificationService → NotificationManager → NotificationModel (ListModel)
                                              └── notifWrapper ListView (binding)
                                                   └── BlobRect (binding, no PopupRegistry)

IpcHandler (shell.qml) → PopupRegistry.launcherPanels[name] 
                        → LauncherPanel.toggleLauncher() → root.toggle()
                                                         └── BlobRect (binding)
```

## Known Issues

1. **Launcher not visible** despite debug logs showing toggle() executes, showAnimation=true, calculatedHeight=496. Possible causes:
   - LauncherPanel at wrong y position (anchored bottom, portrait rotation)
   - Container height animation not rendering
   - Behind other shell elements (z-ordering)
   
2. **Multi-monitor IPC routing** — centralized IpcHandler in shell.qml uses `Niri.focused_output_name` to find correct LauncherPanel via `PopupRegistry.launcherPanels[name]`. Should work but untested.

3. **Old PopupRegistry entries** still used by VolumeOSD, WallpaperSelector, HistoryPanel — these still need migration.

## Next Steps

1. **Debug launcher visibility** — add `visible: true` override, check z-order, verify container rendering
2. **Migrate VolumeOSD** → inline OSDPanel with dedicated BlobRect
3. **Migrate WallpaperSelector** → inline bottom panel
4. **Migrate HistoryPanel** → inline right panel  
5. **Remove PopupRegistry** entirely
6. **Remove old window files**

## Keybindings
- Super+Space → `qs ipc call appLauncher toggleLauncher`
- Super+V → `qs ipc call appLauncher toggleClipboard`
- Test 'L' button in top bar (left of workspaces)

## Debug Commands
```
qs log                    # Check runtime errors
qs ipc show               # List registered IPC targets
qs ipc call appLauncher toggleLauncher  # Toggle launcher
niri msg focused-output   # Check which monitor is focused
cat /tmp/niri_status.json # Niri state JSON
```
