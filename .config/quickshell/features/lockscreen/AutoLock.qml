pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.config
import qs.core

Scope {
    id: root

    property bool enableAutoLock: Settings.enableAutoLock
    property bool enableAutoSleep: Settings.enableAutoSleep

    property bool _lockReceived: false

    readonly property bool audioPlaying: Players.list.some(p => p.isPlaying)
    readonly property bool idleAllowed: !Settings.inhibitIdleWhenAudio || !audioPlaying

    // Drop pending lock/sleep if music starts after idle fired
    onAudioPlayingChanged: {
        if (audioPlaying && _lockReceived) {
            _lockReceived = false
            sleepTimer.stop()
        }
    }

    IdleMonitor {
        enabled: root.enableAutoLock && root.idleAllowed
        timeout: Settings.idleLockTimeout
        respectInhibitors: true

        onIsIdleChanged: {
            if (isIdle && !root._lockReceived) {
                if (!root.idleAllowed)
                    return
                root._lockReceived = true
                Quickshell.execDetached(["quickshell", "ipc", "call", "lock", "lockSession"])
                if (root.enableAutoSleep)
                    sleepTimer.restart()
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
            // Skip suspend while audio is playing; don't force past inhibitors
            if (!root.idleAllowed)
                return
            Quickshell.execDetached(["systemctl", "suspend"])
        }
    }
}
