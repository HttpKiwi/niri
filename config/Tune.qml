pragma Singleton

import QtQuick
import Quickshell

/**
 * Tune - every knob in the shell. No settings UI: edit this file.
 */
Singleton {
    readonly property string home: Quickshell.env("HOME")

    // Wallpaper: shared with v1 so both shells show the same one
    readonly property string wallpapersDir: home + "/Pictures/Wallpapers"
    readonly property string currentWallpaperFile: wallpapersDir + "/current_wallpaper.json"
    readonly property string fallbackWallpaper: wallpapersDir + "/wallhaven-exjy6w_1920x1080.png"

    // Type (Fraunces / Nunito are the design faces; Noto until they're installed)
    readonly property string displayFont: "Noto Serif"
    readonly property string uiFont: "Noto Sans"
    readonly property string iconFont: "Material Symbols Rounded"

    // Palette (sampled from the forest mockup; matugen takes over later)
    readonly property color sun: "#c9dc7c"      // lime of a sunlit clearing
    readonly property color ember: "#f0c36a"    // fireflies, night accent
    readonly property color parch: "#ece6d3"    // warm light text
    readonly property color moss: "#1b2824"     // chrome surface

    // Workspace lights (left edge)
    readonly property int lightSize: 20         // idle workspace
    readonly property int lightActive: 40       // where you are
    readonly property int lightSpacing: 40
    readonly property real lightDrift: 3        // px of float

    // The left strip: reserved (windows never go under it) and the overlay's width at rest
    readonly property int stripWidth: 44

    // Island seed (bottom-left)
    readonly property int seedSize: 28
    readonly property int seedMargin: 8

    // Island faces (grow right from the seed)
    readonly property int pillHeight: 36
    readonly property int islandMaxWidth: 460   // overlay widens to this while a face shows
    readonly property int volumeHold: 1800      // ms
    readonly property int messageHold: 4200
    readonly property int urgentHold: 9000
    readonly property int maxMotes: 5

    // Menu (the island grown into a pebble)
    readonly property int menuWidth: 640
    readonly property int menuHeight: 480
    readonly property int menuRows: 8
    // The main search shows a few per category, not everything that matches
    readonly property int limitAppsTools: 4
    readonly property int limitWindows: 2
    readonly property int limitPhone: 2
    readonly property int limitInboxGroup: 3   // per app in the inbox, until you expand it
    readonly property real scrimOpacity: 0.3

    // Saved state and lists
    readonly property string stateFile: (Quickshell.env("XDG_STATE_HOME") || home + "/.local/state") + "/grove/state.json"
    readonly property int historyMax: 60
    readonly property int clipMax: 60
    readonly property string nectarlinkData: home + "/.local/share/Nectarlink"

    // Recording: capture with wf-recorder, encode on the Intel iGPU, never the RX 580 (VCE hangs it)
    readonly property string encodeDevice: "/dev/dri/by-path/pci-0000:00:02.0-render"
    readonly property string recordingsDir: home + "/Videos/Recordings"
    readonly property int recordFps: 60

    // Vignette over the wallpaper (helps the lights and island stand out)
    readonly property real vignette: 0.85
    readonly property int vignetteLeftPx: 170

    // Motion
    readonly property int fadeSlow: 700
    readonly property int settle: 650           // springy size/position changes
    readonly property int gradeFade: 2500     // time-of-day transitions
    readonly property int busyFps: 30         // while the island is out of its seed
    readonly property int lifeFps: 8          // shafts, pollen, fireflies, rain

    // Time of day until phase 6 computes sunrise/sunset (Colombia: ~6:00 / ~18:00 all year)
    readonly property real goldenFrom: 16.75  // hours
    readonly property real nightFrom: 18.4
    readonly property real dayFrom: 5.9

    // What each time of day looks like
    readonly property var grades: ({
        day:    { warm: "#ffaa46", warmAmt: 0.0,  cool: "#ffffff", coolAmt: 0.0,  shafts: 1.0,  pollen: 1.0, fireflies: 0.0, clockNight: 0.0 },
        golden: { warm: "#ffa040", warmAmt: 0.55, cool: "#ffffff", coolAmt: 0.0,  shafts: 0.8,  pollen: 0.8, fireflies: 0.0, clockNight: 0.0 },
        night:  { warm: "#ffaa46", warmAmt: 0.0,  cool: "#081028", coolAmt: 0.72, shafts: 0.12, pollen: 0.0, fireflies: 1.0, clockNight: 1.0 }
    })
}
