# Grove — Quickshell v2

Design source: the "Kiwi Shell v2 · Grove" mockup
(https://claude.ai/artifact/WZqfnwkCMd4cKC5ZwHQsbb).
v1 stays untouched in `~/Projects/niri/.config/quickshell` (stowed to `~/.config/quickshell`).

## What the shell is

- **Rest:** the wallpaper, a clock blended into it, a column of floating lights on the
  left (one per workspace, amber motes for unread), and a small "island" seed in the
  bottom-left corner. Nothing else.
- **Island:** one shape that morphs from the corner into volume, recording, a one-line
  message, or the full menu. A message shrinks back and leaves a mote that drifts to the lights.
- **Menu:** the island grown into a pebble; the desktop blurs and dims behind it.
  One palette: apps, windows, calculator/units, tools (OCR, QR, color, emoji),
  phone (NectarLink), clipboard, system.
- **Alive:** time-of-day color grade (day / golden hour / night), light shafts,
  pollen or fireflies, rain. All of it pauses on fullscreen.
- **No settings UI.** Constants live in `Tune.qml`. Changing the shell means editing it.

## Lessons from v1 (and the rule each one becomes)

| v1 mistake | Evidence | v2 rule |
|---|---|---|
| Many layer windows per monitor | Each one is a GL context + render thread + Mesa workers (~30 MB) | Exactly two windows per monitor: **Backdrop** (background layer) and **Overlay** (top layer, input mask = what's drawn) |
| Seven panel flags + mutex handlers + hand-wired masks, blobs and focus | Adding the phone panel touched 5 files | One `mode` per monitor (`rest` / `menu`) plus an island queue. Mask, focus and blur derive from it |
| Settings pages for everything | ~46 slider blocks, `shell-prefs.json`, `_prefsKeys` | `Tune.qml` constants. Only runtime state (current wallpaper, app usage, unread) is persisted |
| Saves racing loads | `shell_data.json` clobbered before load; `Settings.qml` emptied by a bad rewrite | One `Store` per file: `FileView` with `blockLoading`, a `loaded` guard, atomic `setText` |
| Animations on singletons | Chrome froze at unlock | Services expose state only. Every animation lives in an item inside a window |
| Lock state split in two | `sessionLocked=false` but `stateLocked=true` → chrome stayed hidden | Lock state is `WlSessionLock.locked`, nothing else |
| Shelling out and polling | ~25 `Process` objects, 1 s pollers | Native services: Pipewire, Mpris, Notifications server, Niri event stream. `Process` only for one-shot tools (qalc, tesseract, zbarimg, grim/slurp) |
| C++ blob plugin | Out-of-tree build, RPATH, Qt-version rebuilds | No plugins. Organic shapes from one `pebble.frag` ShaderEffect (SDF + grain) |
| Wallpaper scaling | Qt ignores `sourceSize` with a clip rect; portrait walls had gaps | `sourceSize` + `PreserveAspectCrop`, never both clip and size. ffprobe decides still vs video |
| Reload gotchas | qs watches inodes; `sed -i`/`git checkout` broke the watch | Dev runs with `qs -p ~/Projects/grove/shell.qml`; `bin/grove reload` forces a reload |
| Memory creep | 343 MB heap / 84 threads before fixes; v1 fresh 375–470 MB RSS, 51 threads | Budget: **< 375 MB RSS (v1's best fresh), < 1 % idle CPU**, no growth over a day; checked every phase |

Keep from v1 as-is: `mesa_glthread=false` in the spawn env; the recording pipeline
(wf-recorder → ffmpeg `h264_vaapi` on the **Intel iGPU only — never the RX 580's VCE**);
matugen; NectarLink `--task` hooks; IPC-first keybinds.

## Layout

```
grove/
  shell.qml            Variants per screen → Backdrop + Overlay; all IpcHandlers
  config/Tune.qml      singleton: palette (from matugen), sizes, motion, location
  services/            Niri, Audio, Media, Notifs, Recorder, Phone, Wallpaper, Store, Ambience
  backdrop/            Backdrop (window), Wallpaper (crossfade), Grade (shader), Life (particles), WorldClock
  overlay/             Overlay (window), Lights, Island, faces/{Volume,Rec,Message,Menu}Face
  menu/                Menu, Results, sources/{Apps,Windows,Calc,Tools,Phone,Clipboard,System}
  lock/                Lock (WlSessionLock + PAM)
  shaders/             pebble.frag, grade.frag (+ compiled .qsb)
  bin/grove            switch v1 ↔ v2, reload, ipc wrapper
```

Ported from v1, cleaned while moving: `Niri.qml`, `Audio.qml`, `Players.qml`,
`NotificationService.qml` (server half only), `ScreenRecord.qml`, `Caffeine.qml`,
`MatugenRunner.qml` (switch to a hue-preserving scheme), `FuzzyMatcher.qml`,
`AppLauncherSource` (usage sort) and `ClipboardLauncherSource` (cliphist), lockscreen PAM flow.

Dropped: blob plugin, `PocketFrame`, `UnifiedBar`, pills, Settings pages, `PanelState(s)`,
OSD, control center, calendar pocket, minimap, ring gauges, GIF search.

## Running both shells

Only one shell can own the notification server and the session lock, so they swap rather than run together.

- `bin/grove on` — `qs kill` v1, start v2 with `qs -p ~/Projects/grove/shell.qml` (same env as niri's spawn line).
- `bin/grove off` — kill v2, start v1 again.
- niri needs `place-within-backdrop` for namespace `grove:backdrop` (in v1's `config.kdl`),
  or the wallpaper slides with workspaces and the overview has no backdrop.
- niri binds stay pointed at a `grove ipc …` wrapper that forwards to whichever shell runs,
  so keybinds survive the swap.

## Measured baseline (phase 0, two screens: 1920×1080 + 1080×1920)

| Config | RSS | Anon | Threads |
|---|---|---|---|
| Empty Quickshell (`ShellRoot {}`) | 130 MB | 41 MB | 10 |
| Two bare layer windows | 175 MB | 74 MB | 22 |
| + one wallpaper image per screen | 224–253 MB | 121–149 MB | 29 |
| Grove phase 0 | 244–258 MB | ~155 MB | 30 |
| Grove phase 1 (shader backdrop, life at 12 fps) | 316 MB (300 with life frozen) | 217 MB | 32 |
| Grove phase 2 (+ overlay strip, lights, seed; life at 8 fps) | ~340 MB | — | 40 |
| Grove phase 3 (+ notification server, Pipewire, island faces) | 354 MB | — | 41 |
| v1 (fresh, for reference) | 375–470 MB | — | 51–52 |

The first textured draw costs ~50 MB once per process regardless of image size
(a 1080p PNG cost more than the 4K JPEG; `cache: false` and malloc tuning changed
nothing), so text and images make it unavoidable. The custom shader pipeline adds ~50 MB
more whether or not it animates (phase 1). Budget: **stay below v1's fresh 375 MB with
both windows per screen, < 1 % idle CPU, flat over a day.**

## Phases (each ends with a commit and the budget check)

0. **Scaffold** — repo, `shell.qml`, `Tune.qml`, `bin/grove`, Backdrop with the wallpaper only.
   Check: swap on/off works; baseline RSS and thread count recorded.
1. **Backdrop** ✓ — crossfading wallpaper, blended world clock, day / golden / night grade,
   light shafts, procedural pollen / fireflies / rain, all one shader pass (`shaders/world.frag`)
   ticking at `Tune.lifeFps` = 12. Measured 0.9 % CPU, 316 MB. Fullscreen pause → phase 2.
2. **Overlay skeleton** ✓ — 0.6 % CPU with windows open. Lessons: a full-screen transparent
   overlay repainting at 12 fps cost ~4 % (every tick repaints the whole buffer), so at rest the
   overlay is a 112 px strip; backdrop life pauses while the active workspace has windows
   (niri also throttles hidden surfaces, which made phase 1's 0.9 % look better than it was);
   the clock texture re-renders once a minute (`live: false`). Unread motes move to phase 3.
   Original scope: Lights from the Niri workspace stream, unread motes, island seed,
   input mask limited to the lights and the island. Check: clicks pass through everywhere else.
   Niri service reads `$NIRI_SOCKET` directly (v1's `Niri 0.1` plugin lives in v1's folder).
   Pause the backdrop's life timer while a fullscreen window covers that screen.
3. **Island faces** ✓ — 0.8 % CPU, 354 MB. The overlay widens to 460 px only while a face shows.
   niri volume keys now call `bin/grove ipc audio …` (works on v1 or v2). Notification history
   is in memory only; persistence comes with the menu in phase 4.
   Original scope: volume (Pipewire), recording (Recorder), message (grove becomes the
   notification daemon), mote drop into the lights, a queue so faces never overlap.
4. **Menu** — island → pebble morph, blur via `BackgroundEffect.blurRegion` only while open
   (niri layer-rule for the `grove` namespace), keyboard grammar (type, ↑↓, Enter, Esc).
   Sources: apps, windows, calc/units (`qalc`), clipboard, OCR, QR scan/make, color
   (`niri msg pick-color`), emoji, phone, system.
5. **Lock** — the scene at night grade, clock large, password field as a pebble.
6. **Ambience** — automatic time of day from sunrise/sunset for a hardcoded location; optional rain from a weather lookup.
7. **Switch** — v2 becomes the default spawn in niri; v1 stays for rollback until removed.

## Open items

- `Tune.location` (lat/lon) for sunrise/sunset — needs a value.
- Install for phase 4: `libqalculate tesseract tesseract-data-eng tesseract-data-spa zbar`.
- Fullscreen detection from the Niri event stream (verify which field niri 26.04 exposes).
