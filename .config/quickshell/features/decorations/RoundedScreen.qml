import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import qs.core
import qs.config
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

            Item {
                id: cornersRoot
                anchors.fill: parent
                // Animated by this window's render loop (see LockState)
                opacity: LockState.chromeHidden ? 0 : 1
                Behavior on opacity {
                    id: cornersReveal
                    SequentialAnimation {
                        PauseAnimation {
                            duration: cornersReveal.targetValue > 0.5 ? Settings.lockscreenChromeRestoreDelay : 0
                        }
                        NumberAnimation {
                            duration: Settings.lockscreenEngageDelay
                            easing.type: Easing.InOutCubic
                        }
                    }
                }

            Corner {
                id: topLeftCorner
                anchors.top: parent.top
                anchors.left: parent.left
                corner: 0  // topLeft
                radius: Settings.screenCornerRadius
                color: "black"
            }

            Corner {
                id: topRightCorner
                anchors.top: parent.top
                anchors.right: parent.right
                corner: 1  // topRight
                radius: Settings.screenCornerRadius
                color: "black"
            }

            Corner {
                id: bottomLeftCorner
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                corner: 3  // bottomLeft
                radius: Settings.screenCornerRadius
                color: "black"
            }

            Corner {
                id: bottomRightCorner
                anchors.bottom: parent.bottom
                anchors.right: parent.right
                corner: 2  // bottomRight
                radius: Settings.screenCornerRadius
                color: "black"
            }
            }
            
            mask: Region {
                item: null
            }
        }
    }
}
