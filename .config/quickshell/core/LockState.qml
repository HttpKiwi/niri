pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick

/**
 * LockState - Shared lock session state and chrome reveal progress (0–1)
 */
QtObject {
    id: root

    property bool locked: false
    property bool engaging: false
    property real chromeReveal: 1

    readonly property bool shellRetracted: locked || engaging || chromeReveal < 0.01

    // In-process lock request (AutoLock / other modules) — LockScreen handles it
    signal lockRequested()

    function requestLock() {
        if (locked || engaging)
            return;
        lockRequested();
    }
}
