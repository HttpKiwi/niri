pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.config

/**
 * DotMatrixDemo - Prototype floating square showing the dot-matrix aurora effect.
 * Screen-center 480x480 panel at Overlay layer. Click-through outside the square.
 * Remove from shell.qml once the effect is approved.
 */
PanelWindow {
    id: root

    visible: false 
    screen: Quickshell.primaryScreen
    exclusionMode: ExclusionMode.Ignore
    exclusiveZone: -1
    WlrLayershell.namespace: "quickshell:dotMatrixDemo"
    WlrLayershell.layer: WlrLayer.Overlay
    color: "transparent"

    anchors {
        top: true
        left: true
        right: true
        bottom: true
    }

    readonly property real squareSize: 480

    Item {
        id: demoSquare
        width: root.squareSize
        height: root.squareSize
        anchors.centerIn: parent

        Rectangle {
            id: clipBox
            anchors.fill: parent
            radius: 20
            color: "transparent"
            clip: true
            border.color: Theme.borderDefault
            border.width: 1

            DotMatrixBackground {
                anchors.fill: parent
            }
        }
    }

    mask: Region {
        item: demoSquare
    }

    Component.onCompleted: {
        console.log("DotMatrixDemo: prototype loaded at screen center")
    }
}
