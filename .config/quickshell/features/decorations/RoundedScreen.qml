import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import qs.core
import qs.features.decorations

/**
 * RoundedScreen - Rounded screen corners
 * Creates rounded corners for all screens
 */
Scope {
    id: screenCorners
    
    property var targetScreen: null
    readonly property Toplevel activeWindow: ToplevelManager.activeToplevel
    
    Variants {
        model: targetScreen ? [targetScreen] : (Quickshell.screens || [])
        
        PanelWindow {
            property var modelData
            
            visible: modelData
            screen: modelData
            exclusionMode: ExclusionMode.Ignore
            exclusiveZone: 0
            WlrLayershell.namespace: "quickshell:screenCorners"
            WlrLayershell.layer: WlrLayer.Overlay
            color: "transparent"
            
            anchors {
                top: true
                left: true
                right: true
                bottom: true
            }
            
            Corner {
                id: topLeftCorner
                anchors.top: parent.top
                anchors.left: parent.left
                corner: 0  // topLeft
                radius: 12
                color: "black"
            }

            Corner {
                id: topRightCorner
                anchors.top: parent.top
                anchors.right: parent.right
                corner: 1  // topRight
                radius: 12
                color: "black"
            }
            
            Corner {
                id: bottomLeftCorner
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                corner: 3  // bottomLeft
                radius: 12
                color: "black"
            }
            
            Corner {
                id: bottomRightCorner
                anchors.bottom: parent.bottom
                anchors.right: parent.right
                corner: 2  // bottomRight
                radius: 12
                color: "black"
            }
            
            mask: Region {
                item: null
            }
        }
    }
}
