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
    // Translucent tint + hairline border so the bar chrome shows through.
    // Driven by the Settings → Appearance → Glass sliders.
    property bool glass: true
    signal clicked()

    // Default content goes into the sized content host (not the click overlay)
    default property alias contentItem: contentContainer.data

    color: glass ? Theme.glass(Settings.glassOpacity, Settings.glassTintStrength) : Theme.pillBackground
    border.width: glass ? 1 : 0
    border.color: Theme.glassBorder(Settings.glassBorderOpacity, Settings.glassTintStrength)
    radius: Settings.barPillRadius
    implicitHeight: Settings.barPillHeight
    implicitWidth: contentContainer.implicitWidth + horizontalPadding

    // Soft top highlight, like light catching the glass edge
    Rectangle {
        visible: root.glass
        anchors.fill: parent
        anchors.margins: root.border.width
        radius: root.radius - root.border.width
        gradient: Gradient {
            GradientStop { position: 0.0; color: Theme.withAlpha(Theme.textPrimary, 0.08) }
            GradientStop { position: 0.5; color: "transparent" }
        }
    }

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
