pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.config

Scope {
    id: lockScope

    WlSessionLock {
        id: lock

        signal unlockRequested

        LockSurface {
            lock: lock
        }
    }

    Component.onCompleted: {
        lock.locked = false  
    }

    IpcHandler {
        target: "lock"

        function lockSession() {
            lockTimer.restart()
        }

        function unlockSession() {
            lock.unlockRequested()
        }

        function isLocked() {
            return lock.locked
        }
    }

    Timer {
        id: lockTimer
        interval: 100
        onTriggered: {
            lock.locked = true
        }
    }
}
