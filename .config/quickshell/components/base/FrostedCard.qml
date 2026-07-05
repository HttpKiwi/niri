pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import qs.config

/**
 * FrostedCard - Internal backdrop blur + matugen tint (no compositor blur)
 * Samples blurSource behind this card, blurs it, then tints for readability.
 */
Item {
    id: root

    property Item blurSource: null
    property real blurAmount: 0.65
    property int contentPadding: 12
    property real glassOpacity: Settings.glassOpacity
    property real tintStrength: Settings.glassTintStrength
    property color cardBorderColor: Theme.glassBorder(Settings.glassBorderOpacity, tintStrength)

    default property alias contentData: contentContainer.data

    readonly property point _srcPos: blurSource
        ? mapToItem(blurSource, 0, 0)
        : Qt.point(0, 0)

    // Blurred slice of the aurora (or other) background
    ShaderEffectSource {
        id: grab
        anchors.fill: parent
        sourceItem: root.blurSource
        sourceRect: Qt.rect(root._srcPos.x, root._srcPos.y, root.width, root.height)
        live: true
        hideSource: false
        visible: false
    }

    MultiEffect {
        anchors.fill: parent
        source: grab
        blurEnabled: root.blurSource !== null
        blurMax: 48
        blur: root.blurAmount
        autoPaddingEnabled: false
    }

    // Tinted glass overlay
    Rectangle {
        anchors.fill: parent
        radius: Settings.cardRadius
        color: Theme.glass(root.glassOpacity, root.tintStrength)
        border.color: root.cardBorderColor
        border.width: Settings.cardBorderWidth
        antialiasing: true
    }

    Item {
        id: contentContainer
        anchors.fill: parent
        anchors.margins: root.contentPadding
    }
}
