import QtQuick
import Quickshell
import Quickshell.Io
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
    
    width: dot.width
    height: Settings.workspaceIndicatorHeight
    
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
            try {
                const command = ["niri", "msg", "action", "focus-workspace", `${root.workspace.idx}`]
                Qt.createQmlObject(`
                    import Quickshell.Io;
                    Process {
                        command: ${JSON.stringify(command)}
                        running: true
                    }
                `, root)
            } catch (e) {
                console.error("Error switching workspace:", e)
            }
        }
    }
}
