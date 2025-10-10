import QtQuick
import qs.config

/**
 * FadeAnimation - Reusable fade animation
 * Provides smooth opacity transitions
 */
Item {
    id: root
    
    // Properties
    property Item target
    property bool running: false
    property int duration: Settings.animationDurationMedium
    
    onRunningChanged: {
        if (target) {
            target.opacity = running ? 1 : 0
        }
    }
    
    Component.onCompleted: {
        if (target) {
            target.opacity = running ? 1 : 0
        }
    }
    
    Behavior on target.opacity {
        NumberAnimation {
            duration: root.duration
            easing.type: Easing.OutQuad
        }
    }
}
