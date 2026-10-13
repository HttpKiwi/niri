pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland

/**
 * Caffeine - Wayland idle inhibitor ("keep awake")
 * IdleMonitor with respectInhibitors skips auto-lock/sleep while enabled.
 */
Item {
    id: root

    visible: false

    property bool enabled: false

    function toggle() {
        enabled = !enabled;
    }

    function enable() {
        enabled = true;
    }

    function disable() {
        enabled = false;
    }

    IdleInhibitor {
        enabled: root.enabled
        window: PanelWindow {
            implicitWidth: 0
            implicitHeight: 0
            color: "transparent"
            mask: Region {}
        }
    }
}
