import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import qs.config
import qs.core

/**
 * ScreenBorder - Screen border with rounded corners
 * Creates a border around the screen with rounded corners
 */
PanelWindow {
    id: screenBorder

    implicitWidth: Screen.width
    implicitHeight: Screen.height
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "quickshell:screenBorder"
    exclusiveZone: 0
    visible: !Niri.is_overview

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
        border.width: 6
        border.color: Color.background
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
