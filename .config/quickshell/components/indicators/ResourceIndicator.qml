import QtQuick
import Quickshell.Widgets
import qs.core
import qs.config

/**
 * ResourceIndicator - CPU and Memory usage display for the bar
 * Shows current system resource usage
 */
WrapperItem {
    id: root
    
    Row {
        spacing: 4
        anchors.centerIn: parent
        
        Text {
            text: `C: ${Math.round(ResourceUsage.cpuUsage * 100)}%`
            color: Theme.textPrimary
            font.pixelSize: Settings.fontSizeLarge
        }
        
        Text {
            text: `M: ${Math.round(ResourceUsage.memoryUsedPercentage * 100)}%`
            color: Theme.textPrimary
            font.pixelSize: Settings.fontSizeLarge
        }
    }
}
