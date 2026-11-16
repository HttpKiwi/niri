import QtQuick
import qs.config
import qs.services

/**
 * Island - the one shape that becomes every popup. Phase 2: the seed at rest,
 * a dim pebble with a breathing core. Faces (volume, recording, message,
 * menu) grow out of it in phases 3–4.
 */
Item {
    id: root

    required property real t
    readonly property bool night: Ambience.phase === "night"

    width: Tune.seedSize
    height: Tune.seedSize

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        opacity: 0.72
        gradient: Gradient {
            GradientStop { position: 0; color: Qt.rgba(0.165, 0.227, 0.2, 0.92) }
            GradientStop { position: 1; color: Qt.rgba(0.094, 0.141, 0.122, 0.95) }
        }
        border.width: 1
        border.color: Qt.rgba(Tune.parch.r, Tune.parch.g, Tune.parch.b, 0.07)
    }

    Glow {
        anchors.centerIn: parent
        width: parent.width * 0.62
        height: width
        scale: 0.9 + 0.1 * Math.sin(root.t * 2 * Math.PI / 6)
        opacity: 0.65 + 0.35 * Math.sin(root.t * 2 * Math.PI / 6)
        core: root.night ? "#fff3cf" : "#fbfde6"
        halo: root.night ? Tune.ember : Tune.sun
        coreSize: 0.12
        Behavior on halo { ColorAnimation { duration: Tune.gradeFade } }
    }
}
