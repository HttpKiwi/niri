pragma ComponentBehavior: Bound

import QtQuick
import qs.config

/**
 * DotMatrixBackground - Volumetric gradient with micro-dot texture
 * Dark top → soft luminous bottom vertical gradient, layered with slow-drifting
 * fbm haze for volumetric feel, overlaid with subtle micro-dot texture.
 * Colors derive from matugen palette via Theme; live-updates with wallpaper changes.
 */
Item {
    id: root

    property color color1: Theme.primary
    property color color2: Theme.accentSecondary
    property color color3: Theme.tertiary
    property color baseColor: Theme.surfaceBase
    property real cellSize: 7
    property real dotSize: 0.3
    property real animationSpeed: 0.2
    property real auroraIntensity: 1
    property real time: 0

    ShaderEffect {
        id: effect
        anchors.fill: parent
        blending: false

        property real time: root.time
        property color color1: root.color1
        property color color2: root.color2
        property color color3: root.color3
        property color baseColor: root.baseColor
        property real cellSize: root.cellSize
        property real dotSize: root.dotSize
        property real animSpeed: root.animationSpeed
        property real intensity: root.auroraIntensity
        property real itemWidth: root.width
        property real itemHeight: root.height
        property real offsetX: 0
        property real offsetY: 0

        fragmentShader: Qt.resolvedUrl("shaders/test10.qsb")
    }

    NumberAnimation on time {
        from: 0
        to: 1000
        duration: 1000000
        running: root.visible
        loops: Animation.Infinite
    }
}
