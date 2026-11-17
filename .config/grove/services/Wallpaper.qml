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

    property string saved: path     // what's on disk; `path` may differ while previewing

    // Matugen palette for the pebble: top and bottom of its fill (straight alpha)
    property color tintTop: Qt.rgba(0.165, 0.227, 0.2, 0.94)
    property color tintBottom: Qt.rgba(0.094, 0.141, 0.122, 0.96)

    // dark | light: what matugen themes the other apps with (Grove itself stays dark)
    readonly property string mode: Store.prefs.mode ?? "dark"
    function setMode(m) {
        Store.setPref("mode", m);
        Quickshell.execDetached(["gsettings", "set", "org.gnome.desktop.interface", "color-scheme", m === "light" ? "prefer-light" : "prefer-dark"]);
        _theme(saved);
    }

    property string _queued: ""
    function _theme(p) { _queued = p; if (!matugen.running) _runQueued(); }
    function _runQueued() {
        if (!_queued) return;
        matugen.command = [Tune.matugenScript, _queued, "--scheme-type", "scheme-tonal-spot", "--mode", root.mode, "--contrast", "0"];
        _queued = "";
        matugen.running = true;
    }
    Process {
        id: matugen
        onExited: root._runQueued()
    }
    FileView {
        path: Tune.matugenColors
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            try {
                const c = JSON.parse(text());
                // the pebble keeps to dark surfaces: its text is light
                if (root.mode === "dark" && c.surface_container_high && c.surface_container) {
                    const a = Qt.color(c.surface_container_high), b = Qt.color(c.surface_container);
                    root.tintTop = Qt.rgba(a.r, a.g, a.b, 0.94);
                    root.tintBottom = Qt.rgba(b.r, b.g, b.b, 0.96);
                }
            } catch (e) {
                console.warn("Wallpaper: unreadable", Tune.matugenColors, e);
            }
        }
    }

    function set(p) {
        if (!p) return;
        saved = p;
        _theme(p);
        path = p;
        file.setText(JSON.stringify({ path: p }) + "\n");
    }
    // try one on without saving; revert() puts the saved one back
    function preview(p) { if (p) path = p; }
    function revert() { path = saved; }
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
                if (p) { root.path = p; root.saved = p; }
            } catch (e) {
                console.warn("Wallpaper: unreadable", Tune.currentWallpaperFile, e);
            }
        }
    }
}
