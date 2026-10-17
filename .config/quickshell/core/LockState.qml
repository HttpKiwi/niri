pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import qs.config

/**
 * LockState - Shared lock session state and chrome reveal progress (0–1)
 */
QtObject {
    id: root

    property bool locked: false
    property bool engaging: false
    // Bar/frame visibility: a binding on the lock state, animated by the Behavior.
    // It was set imperatively by an animation + restore timer, and a missed step
    // left it at 0 after unlock (bar slid away, frame invisible) with no recovery.
    readonly property bool chromeHidden: locked || engaging
    property real chromeReveal: chromeHidden ? 0 : 1

    Behavior on chromeReveal {
        id: revealBehavior
        SequentialAnimation {
            // Let the lock surface fade first before the chrome comes back
            PauseAnimation {
                duration: revealBehavior.targetValue > 0.5 ? Settings.lockscreenChromeRestoreDelay : 0
            }
            NumberAnimation {
                duration: Settings.lockscreenEngageDelay
                easing.type: Easing.InOutCubic
            }
        }
    }

    readonly property bool shellRetracted: locked || engaging || chromeReveal < 0.01

    // In-process lock request (AutoLock / other modules) — LockScreen handles it
    signal lockRequested()

    function requestLock() {
        if (locked || engaging)
            return;
        lockRequested();
    }
}
