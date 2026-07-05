pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick

/**
 * ChromeClock - Shared timebase for blob chrome aurora.
 * Elapsed seconds from shell start; phase-locks every chrome surface.
 */
QtObject {
    id: root

    property real time: 0
    property real _epochMs: 0

    // ~30fps is enough for slow aurora; halves paint traffic vs 60fps
    property Timer tick: Timer {
        interval: 33
        running: true
        repeat: true
        onTriggered: {
            if (root._epochMs <= 0)
                root._epochMs = Date.now();
            root.time = (Date.now() - root._epochMs) / 1000.0;
        }
    }

    Component.onCompleted: root._epochMs = Date.now()
}
