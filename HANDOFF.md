# Handoff — niri / Quickshell / Kiwiboard

**Date:** 2026-10-03  
**Repo:** `/home/httpkiwi/niri` (GNU Stow → `~/.config/…`)  
**Branch:** `main` (many uncommitted local changes)  
**Session transcript:** [calendar + bat + settings](c4062cf2-a4c3-4258-9058-e5e7bbc57662)

Always edit under `/home/httpkiwi/niri/`, never orphan files only under `~/.config/`.  
Never `killall niri`. After QML edits: `qs log`. After niri KDL: `niri validate`.

---

## What this project is

Custom desktop: **Niri** (compositor) + **Quickshell** (QML shell) + **Matugen** (Material colors). Bar uses **UnifiedBar + PocketFrame** with Caelestia blob chrome. Related hardware: **Kiwiboard** ZMK split (dongle + L/R halves, 150 mAh cells).

---

## Shipped / in-tree (uncommitted)

### Calendar pocket
- `features/calendar/CalendarPanel.qml` — month view from bar date/time
- `features/calendar/ColombianHolidays.qml` — Colombia holidays + Ley Emiliani
- Wired in `UnifiedBar.qml`, `PocketFrame.qml`, `PanelState.calendar`
- Glass on cards (not whole panel); blob parity with other pockets

### Settings → Modules
- `features/settings/ModulesPage.qml` — bar module toggles
- Settings nav / section card polish elsewhere under `features/settings/`

### Lock / idle
- Fixes across `AutoLock.qml`, `LockState.qml`, `LockScreen.qml` (idle lock/sleep path)
- `core/Caffeine.qml` (new) — idle inhibit helper

### Other uncommitted notables
- `RoundedScreen` ↔ `Settings.screenCornerRadius`
- Control center keyboard nav + hints
- Matugen / Equibop / scripts (`reboot-to-windows.sh`, `discord-wayland.sh`)
- `split-6x3-ergogen.yaml` (case; 502030 pocket, cells are 150 mAh)
- Local blob build artifacts under `.config/quickshell/qml/Caelestia/Blobs/` — do not treat as source of truth

---

## Incomplete / next actions

### 1. Glass chrome theme (planned, not built)
User asked for transparent/glass shell frame. Plan from prior turn:
1. Multiply `blob.frag` output by `color.a`; rebuild blobs (`scripts/build-blobs-plugin.sh`)
2. Add `chromeOpacity` pref + Appearance slider
3. Bind `BlobGroup` color/baseColor to `Theme.withAlpha(surfaceBase, chromeOpacity)` in `PocketFrame`
4. Expand `WindowBlur` to full chrome when opacity &lt; 1
5. Reload qs, verify visually

Do **not** assume blob alpha works today — material path largely ignored `color.a`.

### 2. Hygiene / debt (older analysis still valid)
- Legacy unused QML (WallpaperSelector, VolumeOSD, old lock pieces, etc.)
- Rename leftover `historyPanel` mental model if any remains → control center
- Volume: prefer `qs ipc` over raw `wpctl` in niri binds if OSD should always show
- Hardcoded `/home/httpkiwi/` paths in Settings / scripts
- AGENTS.md cache path / plugin install path may lag reality

---

## Hard constraints

| Do | Don’t |
|----|--------|
| Edit `/home/httpkiwi/niri/.config/…` | Edit only live `~/.config` orphans |
| `niri validate` after KDL | Kill niri / restart session casually |
| Rely on qs auto-reload + `qs log` | Reflash ZMK for UI/slot bugs |
| Stow-aware paths | Commit secrets / large `qml/*.so` without asking |

---

## Quick verification commands

```bash
# Shell errors after QML change
qs log

# Niri config
niri validate

# Lock IPC
qs ipc call lock lockSession
```

---

## Related trees (outside this repo)

| Path | Role |
|------|------|
| `/home/httpkiwi/Projects/Kiwiboard/zmk-config` | Firmware; `CONFIG_ZMK_SLEEP=y` on L/R; dongle central + battery HID proxy |
| `/home/httpkiwi/Projects/Kiwiboard/zmk-split-battery-tray` | Host CLI/tray for dongle HID battery |
| `~/.references/niri-caelestia-shell/`, `~/.references/caelestia-shell/` | Reference implementations |

---

## Suggested resume order

1. Finish the audit plan (`~/.claude/plans/go-ahead-and-plan-smooth-forest.md`): stage 6 refactors.
2. Implement glass chrome plan (shader alpha → pref → PocketFrame → blur).

---

## Commit status

Baseline committed (`chore: snapshot before audit fixes`), audit fixes committed per stage. The keyboard battery bar indicator was removed (never wired; host tooling stays in `~/Projects/Kiwiboard`).
