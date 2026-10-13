import QtQuick
import Quickshell
import qs.config

/**
 * TimeIndicator - Time display for the bar
 * Fixed advance width keeps the pill centered as digits change.
 */
Text {
    id: root

    readonly property string timeFormat: Settings.barTimeFormat || "HH:mm"

    text: Qt.formatTime(clock.date, timeFormat)
    color: Theme.textPrimary
    font.family: Settings.fontFamilyDefault
    font.pixelSize: Settings.fontSizeBar
    font.features: { "tnum": 1 }
    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter

    // Reserve width for the widest typical time string in this format
    width: Math.ceil(metrics.advanceWidth(root._sampleText))
    height: Math.ceil(metrics.height)

    readonly property string _sampleText: {
        // Prefer a wide digit sample so "11:11" doesn't shrink the pill
        if (timeFormat.indexOf("AP") >= 0 || timeFormat.indexOf("ap") >= 0)
            return "00:00 AM";
        if (timeFormat.indexOf("ss") >= 0)
            return "00:00:00";
        return "00:00";
    }

    FontMetrics {
        id: metrics
        font: root.font
    }

    SystemClock {
        id: clock
        precision: root.timeFormat.indexOf("ss") >= 0 ? SystemClock.Seconds : SystemClock.Minutes
    }
}
