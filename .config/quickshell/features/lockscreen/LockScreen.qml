pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.config
import qs.core

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
        LockState.locked = false
        LockState.engaging = false
    }

    Connections {
        target: lock
        function onLockedChanged() {
            if (!lock.locked) {
                // Resume wallpapers immediately — don't wait on chrome reveal delay
                LockState.engaging = false
                LockState.locked = false
            }
        }
    }

    Connections {
        target: LockState
        function onLockRequested() {
            lockScope.lockNow()
        }
    }

    function lockNow() {
        if (lock.locked || LockState.engaging)
            return
        // Chrome retracts via LockState.chromeReveal's binding
        LockState.engaging = true
        LockState.locked = true
        engageTimer.restart()
    }

    IpcHandler {
        target: "lock"

        function lockSession() {
            lockScope.lockNow()
        }

        function isLocked() {
            return lock.locked || LockState.engaging
        }
    }

    Timer {
        id: engageTimer
        interval: Settings.lockscreenEngageDelay
        onTriggered: {
            LockState.engaging = false
            lock.locked = true
        }
    }
}
