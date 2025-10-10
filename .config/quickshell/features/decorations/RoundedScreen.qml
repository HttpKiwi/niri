import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import qs.core

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
            
            visible: true
            screen: {
                try {
                    return modelData || Quickshell.screens[0] || null
                } catch (e) {
                    console.warn("Error getting screen for decoration:", e)
                    return null
                }
            }
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
            
            RoundCorner {
                id: topLeftCorner
                anchors.top: parent.top
                anchors.left: parent.left
                size: 12
                corner: cornerEnum.topLeft
                color: "black"
            }
            
            RoundCorner {
                id: topRightCorner
                anchors.top: parent.top
                anchors.right: parent.right
                size: 12
                corner: cornerEnum.topRight
                color: "black"
            }
            
            RoundCorner {
                id: bottomLeftCorner
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                size: 12
                corner: cornerEnum.bottomLeft
                color: "black"
            }
            
            RoundCorner {
                id: bottomRightCorner
                anchors.bottom: parent.bottom
                anchors.right: parent.right
                size: 12
                corner: cornerEnum.bottomRight
                color: "black"
            }
            
            mask: Region {
                item: null
            }
        }
    }
}
