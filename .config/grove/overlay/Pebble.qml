import QtQuick
import qs.config
import qs.services

/**
 * Pebble - the island's body (shaders/pebble.frag): a rounded shape whose edge
 * drifts like pond water. Fill the island with it; it overhangs by `pad` so the
 * wobble can bulge outwards without being clipped.
 */
ShaderEffect {
    id: root

    property real t: 0
    property real seed: 0
    property real amp: 2
    // corner radii (animated separately: Qt has no vector4 animation)
    property real rtl: 14
    property real rtr: 14
    property real rbr: 14
    property real rbl: 14
    property color fillTop: Wallpaper.tintTop
    property color fillBottom: Wallpaper.tintBottom
    property color edge: Qt.rgba(Tune.parch.r, Tune.parch.g, Tune.parch.b, 0.1)

    readonly property real pad: Math.ceil(amp) + 3
    property size size: Qt.size(parent.width, parent.height)
    property vector4d radii: Qt.vector4d(rtl, rtr, rbr, rbl)

    x: -pad
    y: -pad
    width: parent.width + 2 * pad
    height: parent.height + 2 * pad
    blending: true
    fragmentShader: Qt.resolvedUrl("../shaders/pebble.frag.qsb")

    Behavior on fillTop { ColorAnimation { duration: 900 } }
    Behavior on fillBottom { ColorAnimation { duration: 900 } }
    Behavior on amp { NumberAnimation { duration: Tune.settle } }
    Behavior on rtl { NumberAnimation { duration: Tune.settle } }
    Behavior on rtr { NumberAnimation { duration: Tune.settle } }
    Behavior on rbr { NumberAnimation { duration: Tune.settle } }
    Behavior on rbl { NumberAnimation { duration: Tune.settle } }
}
