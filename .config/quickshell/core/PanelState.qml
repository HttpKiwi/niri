pragma ComponentBehavior: Bound

import QtQuick

/**
 * PanelState - Per-monitor panel open flags.
 * Launcher/wallpaper mutex (bottom). Settings mutex vs other major panels.
 */
QtObject {
    id: root

    property bool launcher: false
    property bool clipboard: false
    property bool osd: false
    property bool wallpaper: false
    property bool controlCenter: false
    property bool settings: false

    signal flagsChanged()

    onLauncherChanged: {
        if (root.launcher) {
            root.wallpaper = false;
            root.settings = false;
        } else {
            root.clipboard = false;
        }
        flagsChanged();
    }

    onWallpaperChanged: {
        if (root.wallpaper) {
            root.launcher = false;
            root.clipboard = false;
            root.settings = false;
        }
        flagsChanged();
    }

    onControlCenterChanged: {
        if (root.controlCenter)
            root.settings = false;
        flagsChanged();
    }

    onSettingsChanged: {
        if (root.settings) {
            root.launcher = false;
            root.wallpaper = false;
            root.clipboard = false;
            root.controlCenter = false;
        }
        flagsChanged();
    }

    onOsdChanged: flagsChanged()
}
