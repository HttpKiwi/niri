import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

Scope {
    id: screenCorners

    readonly property Toplevel activeWindow: ToplevelManager.activeToplevel

    Variants {
        model: Quickshell.screens

        PanelWindow {
            property var modelData

            visible: true
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

            RoundCorner {
                id: topLeftCorner

                anchors.top: parent.top
                anchors.left: parent.left
                size: 12
                corner: cornerEnum.topLeft
            }

            RoundCorner {
                id: topRightCorner

                anchors.top: parent.top
                anchors.right: parent.right
                size: 12
                corner: cornerEnum.topRight
            }

            RoundCorner {
                id: bottomLeftCorner

                anchors.bottom: parent.bottom
                anchors.left: parent.left
                size: 12
                corner: cornerEnum.bottomLeft
            }

            RoundCorner {
                id: bottomRightCorner

                anchors.bottom: parent.bottom
                anchors.right: parent.right
                size: 12
                corner: cornerEnum.bottomRight
            }

            mask: Region {
                item: null
            }

        }

    }

}
