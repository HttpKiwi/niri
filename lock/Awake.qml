import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.services

/**
 * Awake - idle handling: lock after Tune.idleLock seconds without input,
 * suspend Tune.idleSleep seconds after that. Caffeine (and any app holding a
 * Wayland idle inhibitor, like a video playing in the browser) stops both.
 */
Scope {
    id: root

    required property var lock

    IdleInhibitor {
        enabled: Caffeine.enabled
        // the protocol wants a surface: an empty one
        window: PanelWindow {
            implicitWidth: 0
            implicitHeight: 0
            color: "transparent"
            mask: Region {}
        }
    }

    IdleMonitor {
        enabled: !root.lock.locked
        timeout: Tune.idleLock
        respectInhibitors: true
        onIsIdleChanged: if (isIdle) root.lock.lockNow()
    }

    // counted from when the lock engages, since locking can reset the compositor's idle clock
    Timer {
        id: sleep
        interval: Tune.idleSleep * 1000
        running: root.lock.locked && !Caffeine.enabled
        onTriggered: Quickshell.execDetached(["systemctl", "suspend"])
    }
}
