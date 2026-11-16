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

    // Motion
    readonly property int fadeSlow: 700
}
