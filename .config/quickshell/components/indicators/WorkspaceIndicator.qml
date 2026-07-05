import QtQuick
import Quickshell
import qs.core
import qs.config

/**
 * WorkspaceIndicator - Single workspace indicator dot
 * Animated dot that shows workspace state (active/inactive/hover)
 */
Item {
    id: root

    required property var workspace
    required property bool isActive

    width: visible ? dot.width : 0
    height: visible ? Settings.workspaceIndicatorHeight : 0

    Rectangle {
        id: dot
        anchors.verticalCenter: parent.verticalCenter
        width: root.isActive ? Settings.workspaceIndicatorActiveWidth : Settings.workspaceIndicatorInactiveWidth
        height: parent.height
        radius: height / 2
        color: root.isActive ? Theme.stateActive : Theme.stateInactive
        
        Behavior on width {
            NumberAnimation {
                duration: Settings.animationDurationMedium
                easing.type: Settings.easingStandard
            }
        }
        
        Behavior on color {
            ColorAnimation {
                duration: Settings.animationDurationShort
                easing.type: Settings.easingStandard
            }
        }
    }
    
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        enabled: root.visible
        
        onEntered: {
            if (!root.isActive) {
                dot.color = Theme.stateHover
            }
        }
        
        onExited: {
            if (!root.isActive) {
                dot.color = Theme.stateInactive
            }
        }
        
        onClicked: {
            Niri.focusWorkspace(root.workspace.index)
        }
    }
}
