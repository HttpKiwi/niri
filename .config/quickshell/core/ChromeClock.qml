pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import qs.config

/**
 * ChromeClock - Shared timebase for blob chrome aurora.
 * Elapsed seconds from shell start; phase-locks every chrome surface.
 * Pauses when chrome is off, shell is retracted, or no panels are open.
 */
QtObject {
    id: root

    property real time: 0
    property real _epochMs: 0

    readonly property bool shouldTick: Settings.chromeShaderEnabled
        && !LockState.shellRetracted
        && PanelStates.anyPanelOpen

    // 15fps — enough for slow aurora, much less paint traffic than 30/60
    property Timer tick: Timer {
        interval: Settings.chromeClockIntervalMs
        running: root.shouldTick
        repeat: true
        onTriggered: {
            if (root._epochMs <= 0)
                root._epochMs = Date.now()
            root.time = (Date.now() - root._epochMs) / 1000.0
        }
    }

    // Keep timebase continuous across pause/resume so phases don't jump oddly
    onShouldTickChanged: {
        if (shouldTick && _epochMs > 0)
            _epochMs = Date.now() - (time * 1000.0)
    }

    Component.onCompleted: root._epochMs = Date.now()
}
