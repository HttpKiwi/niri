pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.config
import qs.core

/**
 * AutoLock - Idle-driven lock and suspend via ext-idle-notify-v1.
 *
 * Lock uses IdleMonitor. Sleep is a post-lock timer so engaging the lock
 * surface (which can clear compositor idle) does not cancel suspend.
 */
Scope {
    id: root

    readonly property bool audioPlaying: {
        const players = Players.list;
        for (let i = 0; i < players.length; i++) {
            if (players[i] && players[i].isPlaying)
                return true;
        }
        return false;
    }

    readonly property bool idleAllowed: !Settings.inhibitIdleWhenAudio || !audioPlaying
    readonly property bool alreadyLocked: LockState.locked || LockState.engaging

    // Drop pending sleep if media starts before suspend fires
    onAudioPlayingChanged: {
        if (audioPlaying)
            sleepTimer.stop();
    }

    Connections {
        target: LockState
        function onLockedChanged() {
            if (!LockState.locked && !LockState.engaging)
                sleepTimer.stop();
        }
        function onEngagingChanged() {
            if (!LockState.locked && !LockState.engaging)
                sleepTimer.stop();
        }
    }

    function triggerLock() {
        if (root.alreadyLocked)
            return;
        if (!root.idleAllowed)
            return;

        console.log("AutoLock: idle timeout reached, locking");
        LockState.requestLock();

        if (Settings.enableAutoSleep) {
            sleepTimer.interval = Math.max(1, Settings.idleSleepTimeout) * 1000;
            sleepTimer.restart();
            console.log("AutoLock: suspend in", Settings.idleSleepTimeout, "s");
        }
    }

    IdleMonitor {
        id: lockMonitor
        // Stay armed while unlocked; inhibitors optional via pref
        enabled: Settings.enableAutoLock && root.idleAllowed && !root.alreadyLocked
        timeout: Math.max(1, Settings.idleLockTimeout)
        respectInhibitors: Settings.respectIdleInhibitors !== false

        onIsIdleChanged: {
            if (isIdle)
                root.triggerLock();
            else if (!root.alreadyLocked)
                sleepTimer.stop();
        }
    }

    Timer {
        id: sleepTimer
        repeat: false
        onTriggered: {
            if (!Settings.enableAutoSleep)
                return;
            if (!root.idleAllowed) {
                console.log("AutoLock: skip suspend (audio playing)");
                return;
            }
            if (Settings.respectIdleInhibitors && Caffeine.enabled) {
                console.log("AutoLock: skip suspend (caffeine)");
                return;
            }
            console.log("AutoLock: suspending");
            Quickshell.execDetached(["systemctl", "suspend"]);
        }
    }
}
