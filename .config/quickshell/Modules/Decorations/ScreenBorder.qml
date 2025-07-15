import QtQuick
import Quickshell
import Quickshell.Wayland
import "RoundCorner.qml"

PanelWindow {
    id: screenBorder

    width: Screen.width
    height: Screen.height
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Background
    WlrLayershell.namespace: "quickshell:screenBorder"
    exclusiveZone: 0

    anchors {
        top: true
        left: true
        right: true
        bottom: true
    }

    Rectangle {
        id: borderFrame

        anchors.fill: parent
        color: "transparent"
        border.color: "#202b2d"
        border.width: 4
    }

    RoundCorner {
        id: bottomLeftCorner

        corner: cornerEnum.bottomLeft
        size: 12
        color: "#202b2d"
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.leftMargin: 4
        anchors.bottomMargin: 4
    }

    RoundCorner {
        id: bottomRightCorner

        corner: cornerEnum.bottomRight
        size: 12
        color: "#202b2d"
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        anchors.rightMargin: 4
        anchors.bottomMargin: 4
    }

    RoundCorner {
        id: topLeftCorner

        corner: cornerEnum.topLeft
        size: 12
        color: "#202b2d"
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.leftMargin: 4
        anchors.topMargin: 40
    }

    RoundCorner {
        id: topRightCorner

        corner: cornerEnum.topRight
        size: 12
        color: "#202b2d"
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.rightMargin: 4
        anchors.topMargin: 40
    }

}
