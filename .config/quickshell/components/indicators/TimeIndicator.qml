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
    font.pixelSize: Settings.fontSizeLarge
    
    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }
}
