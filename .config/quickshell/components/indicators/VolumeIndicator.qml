import QtQuick
import Quickshell.Widgets
import qs.core
import qs.config

/**
 * VolumeIndicator - Volume control for the bar
 * Shows volume icon, expands to show percentage on hover
 */
WrapperMouseArea {
    id: root
    
    onClicked: Audio.toggleMute()
    hoverEnabled: true
    scrollGestureEnabled: true
    
    onWheel: {
        if (wheel.angleDelta.y > 0)
            Audio.raiseVolume()
        else
            Audio.lowerVolume()
    }
    
    Row {
        spacing: 4
        
        Text {
            id: icon
            topPadding: 2
            fontSizeMode: Text.VerticalFit
            font.family: Settings.fontFamilyIcons
            color: Theme.textPrimary
            font.pixelSize: Settings.fontSizeLarge
            text: Audio.muted ? "\ue04f" : "\ue050"
        }
        
        Text {
            id: percentage
            anchors.verticalCenter: parent.verticalCenter
            opacity: root.containsMouse ? 1 : 0
            width: root.containsMouse ? implicitWidth : 0
            clip: true
            color: Theme.textPrimary
            font.pixelSize: Settings.fontSizeSmall
            text: Audio.getVolume() + "%"
            
            Behavior on width {
                NumberAnimation {
                    duration: Settings.animationDurationMedium
                    easing.type: Settings.easingStandard
                }
            }
            
            Behavior on opacity {
                NumberAnimation {
                    duration: Settings.animationDurationMedium
                    easing.type: Settings.easingStandard
                }
            }
        }
    }
}
