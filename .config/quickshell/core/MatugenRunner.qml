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
        if (runner.running)
            runner.running = false;
        runner.command = buildCommand(wallpaperPath);
        runner.running = true;
    }
}
