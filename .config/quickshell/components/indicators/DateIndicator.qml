import QtQuick
import Quickshell
import qs.config

/**
 * DateIndicator - Date display for the bar
 */
Text {
    id: root

    readonly property string dateFormat: Settings.barDateFormat || "ddd. dd MMM"

    text: Qt.formatDate(clock.date, dateFormat)
    color: Theme.textPrimary
    font.family: Settings.fontFamilyDefault
    font.pixelSize: Settings.fontSizeBar
    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }
}
