pragma Singleton

import QtQuick
import Quickshell

/**
 * Caffeine - "keep awake": while on, an idle inhibitor stops the auto-lock and
 * suspend (lock/Awake.qml). Not remembered across restarts, on purpose.
 */
Singleton {
    property bool enabled: false
    function toggle() { enabled = !enabled; }
}
