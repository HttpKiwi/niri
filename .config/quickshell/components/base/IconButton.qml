import QtQuick
import qs.config

/**
 * IconButton - Reusable icon button component
 * Provides hover states and click handling
 */
Rectangle {
    id: root
    
    // Button properties
    property string icon: "×"
    property int iconSize: 16
    property int buttonSize: 24
    
    // State
    property bool isHovered: false
    
    // Signals
    signal clicked()
    
    // Styling
    width: buttonSize
    height: buttonSize
    radius: buttonSize / 2
    color: isHovered ? Theme.accentContainer : "transparent"
    
    Text {
        text: root.icon
        color: root.isHovered ? Theme.textOnPrimaryContainer : Theme.textSecondary
        font.pixelSize: root.iconSize
        font.bold: true
        anchors.centerIn: parent
        
        Behavior on color {
            ColorAnimation { duration: Settings.animationDurationShort }
        }
    }
    
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        preventStealing: true  // Prevent Flickable from stealing mouse events
        propagateComposedEvents: false  // Don't propagate to parent Flickable
        onEntered: root.isHovered = true
        onExited: root.isHovered = false
        onPressed: mouse.accepted = true
        onReleased: mouse.accepted = true
        onClicked: {
            mouse.accepted = true
            root.clicked()
        }
    }
    
    Behavior on color {
        ColorAnimation { duration: Settings.animationDurationShort }
    }
}
