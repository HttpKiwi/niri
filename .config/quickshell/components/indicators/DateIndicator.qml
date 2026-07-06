import QtQuick
import Quickshell
import qs.config

/**
 * DateIndicator - Date display for the bar
 * Shows current date in ddd. dd MMM format
 */
Text {
    id: root
    
    text: Qt.formatDate(clock.date, "ddd. dd MMM")
    color: Theme.textPrimary
    font.family: Settings.fontFamilyDefault
    font.pixelSize: Settings.fontSizeBar
    
    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }
}
