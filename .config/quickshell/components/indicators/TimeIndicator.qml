import QtQuick
import Quickshell
import qs.config

/**
 * TimeIndicator - Time display for the bar
 * Shows current time in HH:MM format
 */
Text {
    id: root
    
    text: Qt.formatTime(clock.date, "hh:mm")
    color: Theme.textPrimary
    font.family: Settings.fontFamilyDefault
    font.pixelSize: Settings.fontSizeBar
    
    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }
}
