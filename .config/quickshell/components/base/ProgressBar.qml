import QtQuick
import qs.config

/**
 * ProgressBar - Reusable progress bar component
 * Used for volume, brightness, and other progress indicators
 */
Rectangle {
    id: root
    
    // Progress value (0.0 - 1.0)
    property real value: 0.5
    
    // Colors
    property color trackColor: Theme.surfaceHighest
    property color fillColor: Theme.accent
    
    // Dimensions
    property int barHeight: 8
    
    // Styling
    implicitHeight: barHeight
    radius: height / 2
    color: trackColor
    
    Rectangle {
        id: fill
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width * Math.max(0, Math.min(1, root.value))
        height: parent.height
        radius: parent.radius
        color: root.fillColor
        
        Behavior on width {
            NumberAnimation {
                duration: Settings.animationDurationShort
                easing.type: Settings.easingStandard
            }
        }
        
        Behavior on color {
            ColorAnimation { duration: Settings.animationDurationShort }
        }
    }
}
