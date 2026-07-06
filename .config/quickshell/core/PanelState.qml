pragma ComponentBehavior: Bound

import QtQuick

/**
 * PanelState - Per-monitor panel open flags.
 * Launcher and wallpaper are mutually exclusive (both bottom-center).
 */
QtObject {
    id: root

    property bool launcher: false
    property bool clipboard: false
    property bool osd: false
    property bool wallpaper: false
    property bool controlCenter: false

    onLauncherChanged: {
        if (root.launcher)
            root.wallpaper = false;
    }

    onWallpaperChanged: {
        if (root.wallpaper) {
            root.launcher = false;
            root.clipboard = false;
        }
    }
}
