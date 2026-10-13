/**
 * Pill - Reusable pill-shaped container
 * Used for bar indicators, chips, and small containers
 */

import QtQuick
import qs.config

Rectangle {
    id: root

    // Total horizontal padding (split evenly left/right via centerIn)
    property int horizontalPadding: Settings.barPillPadding
    property bool clickable: false
    signal clicked()

    // Default content goes into the sized content host (not the click overlay)
    default property alias contentItem: contentContainer.data

    color: Theme.pillBackground
    radius: Settings.barPillRadius
    implicitHeight: Settings.barPillHeight
    implicitWidth: contentContainer.implicitWidth + horizontalPadding

    Item {
        id: contentContainer
        anchors.centerIn: parent
        implicitWidth: childrenRect.width
        implicitHeight: childrenRect.height
    }

    MouseArea {
        anchors.fill: parent
        enabled: root.clickable
        visible: root.clickable
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
        z: 10
    }
}
