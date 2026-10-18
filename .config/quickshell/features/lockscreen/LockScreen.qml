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
        // Bar/frame retract via LockState.chromeHidden (animated in their windows)
        LockState.engaging = true
        LockState.locked = true
        engageTimer.restart()
    }

    IpcHandler {
        target: "lock"

        function lockSession() {
            lockScope.lockNow()
        }

        function isLocked(): bool {
            return lock.locked || LockState.engaging
        }

        // Live lock/chrome state, for debugging stuck chrome
        function state(): string {
            return JSON.stringify({
                sessionLocked: lock.locked,
                secure: lock.secure,
                stateLocked: LockState.locked,
                engaging: LockState.engaging,
                chromeHidden: LockState.chromeHidden,
                chromeReveal: LockState.chromeReveal
            })
        }
    }

    // Safety net: the shell must never believe it is locked while the session
    // lock is released (reading lock.locked works even when its signal doesn't)
    Timer {
        interval: 1000
        repeat: true
        running: LockState.locked && !LockState.engaging
        onTriggered: {
            if (!lock.locked) {
                console.warn("LockScreen: session unlocked but LockState.locked was true; correcting")
                LockState.locked = false
            }
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
