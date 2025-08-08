import QtQuick
import Quickshell
import Quickshell.Wayland
import "RoundCorner.qml"
import Services 1.0

PanelWindow {
    id: screenBorder

    width: Screen.width
    height: Screen.height
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Top
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
        border.color: Color.background
        border.width: 6
    }

    RoundCorner {
        id: bottomLeftCorner

        corner: cornerEnum.bottomLeft
        size: 18
        color: Color.background
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.leftMargin: 6
        anchors.bottomMargin: 6
        visible: screenBorder.visible
    }

    RoundCorner {
        id: bottomRightCorner

        corner: cornerEnum.bottomRight
        size: 18
        color: Color.background
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        anchors.rightMargin: 6
        anchors.bottomMargin: 6
        visible: screenBorder.visible
    }

    RoundCorner {
        id: topLeftCorner

        corner: cornerEnum.topLeft
        size: 18
        color: Color.background
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.leftMargin: 6
        anchors.topMargin: 40
        visible: screenBorder.visible
    }

    RoundCorner {
        id: topRightCorner

        corner: cornerEnum.topRight
        size: 18
        color: Color.background
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.rightMargin: 6
        anchors.topMargin: 40
        visible: screenBorder.visible
    }

    mask: Region {
        item: borderFrame
        intersection: Intersection.Xor
    }

}
