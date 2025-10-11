/**
 * Pill - Reusable pill-shaped container
 * Used for bar indicators, chips, and small containers
 */

import QtQuick
import qs.config

Rectangle {
    id: root

    // Content padding
    property int horizontalPadding: Settings.barPillPadding
    property int verticalPadding: 0
    // Default content
    default property alias contentItem: contentContainer.data

    // Styling
    color: Theme.pillBackground
    radius: Settings.barPillRadius
    // Auto-size to content
    implicitHeight: Settings.barPillHeight
    implicitWidth: contentContainer.implicitWidth + horizontalPadding

    Item {
        id: contentContainer

        anchors.centerIn: parent
        implicitWidth: childrenRect.width
        implicitHeight: childrenRect.height
    }

}
