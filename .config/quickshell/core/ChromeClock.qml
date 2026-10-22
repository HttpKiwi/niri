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

    // Seconds of ticking time; only advances while ticking, so phases resume smoothly
    property real time: 0

    readonly property bool shouldTick: Settings.chromeShaderEnabled
        && !LockState.shellRetracted
        && PanelStates.anyPanelOpen

    // 15fps — enough for slow aurora, much less paint traffic than 30/60
    property Timer tick: Timer {
        interval: Settings.chromeClockIntervalMs
        running: root.shouldTick
        repeat: true
        onTriggered: root.time += interval / 1000
    }
}
