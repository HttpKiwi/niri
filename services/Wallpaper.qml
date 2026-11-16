pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

/**
 * Wallpaper - the current wallpaper path and the images to pick from. Both
 * shells share current_wallpaper.json, so a pick here moves v1 too (v1 doesn't
 * re-theme from it; Grove has no theme to follow).
 */
Singleton {
    id: root

    property string path: Tune.fallbackWallpaper
    property var files: []          // image paths in Tune.wallpapersDir, newest first

    function set(p) {
        if (!p || p === path) return;
        path = p;
        file.setText(JSON.stringify({ path: p }) + "\n");
    }
    function load() { if (!lister.running) lister.running = true; }
    Process {
        id: lister
        command: ["sh", "-c", "ls -1t \"$1\"/*.png \"$1\"/*.jpg \"$1\"/*.jpeg \"$1\"/*.webp 2>/dev/null", "sh", Tune.wallpapersDir]
        stdout: StdioCollector { onStreamFinished: root.files = text.split("\n").filter(l => l) }
    }

    FileView {
        id: file
        path: Tune.currentWallpaperFile
        atomicWrites: true
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            try {
                const p = JSON.parse(text()).path;
                if (p) root.path = p;
            } catch (e) {
                console.warn("Wallpaper: unreadable", Tune.currentWallpaperFile, e);
            }
        }
    }
}
