import "../../Decorations/"
import QtQuick
import Quickshell
import Quickshell.Io
import Services 1.0

PanelWindow {
    id: root

    property bool is_overview: Niri.is_overview

    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    exclusiveZone: 0

    anchors {
        left: true
        right: true
        top: true
    }

    Item {
        id: barRounding

        visible: !root.is_overview
        height: 30

        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
        }

        RoundCorner {
            anchors.top: parent.bottom
            anchors.left: parent.left
            size: 16
            corner: cornerEnum.topLeft
            color: "white"
            opacity: 1
        }

        RoundCorner {
            anchors.top: parent.bottom
            anchors.right: parent.right
            size: 16
            corner: cornerEnum.topRight
            color: "white"
            opacity: 1
        }

    }

    mask: Region {
        x: 0
        y: 30
        height: 30
        intersection: Intersection.Intersect
    }

}
