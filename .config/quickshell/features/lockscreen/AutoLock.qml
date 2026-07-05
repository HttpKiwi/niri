pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.config

Scope {
    id: root

    property bool enableAutoLock: true
    property bool enableAutoSleep: true

    property bool _lockReceived: false

    IdleMonitor {
        enabled: root.enableAutoLock
        timeout: Settings.idleLockTimeout
        respectInhibitors: true

        onIsIdleChanged: {
            if (isIdle && !root._lockReceived) {
                root._lockReceived = true
                Quickshell.execDetached(["quickshell", "ipc", "call", "lock", "lockSession"])
                if (root.enableAutoSleep) {
                    sleepTimer.restart()
                }
            } else if (!isIdle && root._lockReceived) {
                root._lockReceived = false
                sleepTimer.stop()
            }
        }
    }

    Timer {
        id: sleepTimer
        interval: Settings.idleSleepTimeout * 1000
        onTriggered: {
            Quickshell.execDetached(["systemctl", "suspend-then-hibernate", "-i"])
        }
    }
}
