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
        LockState.chromeReveal = 1
    }

    function hideChrome() {
        chromeRevealAnim.stop()
        chromeRevealAnim.duration = Settings.lockscreenEngageDelay
        chromeRevealAnim.to = 0
        chromeRevealAnim.start()
    }

    function revealChrome() {
        if (lock.locked || LockState.engaging)
            return
        chromeRevealAnim.stop()
        chromeRevealAnim.duration = Settings.lockscreenEngageDelay
        chromeRevealAnim.to = 1
        chromeRevealAnim.start()
    }

    NumberAnimation {
        id: chromeRevealAnim
        target: LockState
        property: "chromeReveal"
        easing.type: Easing.InOutCubic
        onFinished: {
            if (to === 1)
                LockState.chromeReveal = 1
            else if (to === 0)
                LockState.chromeReveal = 0
        }
    }

    Timer {
        id: chromeRestoreTimer
        interval: Settings.lockscreenChromeRestoreDelay
        onTriggered: {
            if (lock.locked || LockState.engaging)
                return
            lockScope.revealChrome()
        }
    }

    Connections {
        target: lock
        function onLockedChanged() {
            if (!lock.locked) {
                // Resume wallpapers immediately — don't wait on chrome reveal delay
                LockState.engaging = false
                LockState.locked = false
                chromeRestoreTimer.restart()
            }
        }
    }

    IpcHandler {
        target: "lock"

        function lockSession() {
            if (lock.locked || LockState.engaging)
                return
            chromeRestoreTimer.stop()
            chromeRevealAnim.stop()
            LockState.engaging = true
            LockState.locked = true
            lockScope.hideChrome()
            engageTimer.restart()
        }

        function unlockSession() {
            lock.unlockRequested()
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
