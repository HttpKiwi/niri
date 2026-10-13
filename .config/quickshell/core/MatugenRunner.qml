pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

/**
 * MatugenRunner - Runs matugen-cache.sh for wallpaper theming.
 */
QtObject {
    id: root

    property var runner: Process {
        running: false

        stdout: SplitParser {
            onRead: data => console.log("Matugen Cache:", data)
        }

        stderr: SplitParser {
            onRead: data => console.log("Matugen Cache:", data)
        }

        // Never kill a run mid-write (leaves Colors.json.tmp.*); start the queued one after
        onExited: root._start()
    }

    property string _pendingPath: ""

    // Coalesce bursts (live sliders, arrow-key wallpaper preview)
    property var debounce: Timer {
        interval: 250
        onTriggered: root._start()
    }

    function buildCommand(wallpaperPath) {
        return [
            Settings.matugenCacheScript,
            wallpaperPath,
            "--scheme-type", MatugenPreferences.schemeType,
            "--mode", MatugenPreferences.colorMode,
            "--contrast", String(MatugenPreferences.contrastLevel)
        ];
    }

    function run(wallpaperPath) {
        if (!wallpaperPath)
            return;
        _pendingPath = wallpaperPath;
        debounce.restart();
    }

    function _start() {
        if (runner.running || !_pendingPath)
            return;
        runner.command = buildCommand(_pendingPath);
        _pendingPath = "";
        runner.running = true;
    }
}
