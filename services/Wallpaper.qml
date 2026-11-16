pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

/**
 * Wallpaper - the current wallpaper path. Read-only for now: v1's picker
 * writes current_wallpaper.json and both shells follow it.
 */
Singleton {
    id: root

    property string path: Tune.fallbackWallpaper

    FileView {
        path: Tune.currentWallpaperFile
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
