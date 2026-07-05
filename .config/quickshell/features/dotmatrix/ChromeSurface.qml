pragma ComponentBehavior: Bound

import QtQuick
import qs.config

/**
 * ChromeSurface - Screen-space organic aurora (matches blob chrome fill)
 */
Item {
    id: root

    property color color1: Theme.primary
    property color color2: Theme.accentSecondary
    property color color3: Theme.tertiary
    property color baseColor: Theme.surfaceBase
    property real cellSize: Settings.chromeCellSize
    property real dotSize: Settings.chromeDotSize
    property real animationSpeed: Settings.chromeAnimSpeed
    property real auroraIntensity: Settings.chromeIntensity
    property real time: 0
    property real screenWidth: width
    property real screenHeight: height
    property real offsetX: 0
    property real offsetY: 0

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
        property real screenWidth: root.screenWidth
        property real screenHeight: root.screenHeight
        property real offsetX: root.offsetX
        property real offsetY: root.offsetY

        fragmentShader: Qt.resolvedUrl("shaders/chrome_aurora.qsb")
    }
}
