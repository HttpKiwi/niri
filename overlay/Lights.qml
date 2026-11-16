pragma ComponentBehavior: Bound

import QtQuick
import qs.config
import qs.services

/**
 * Lights - one floating light per workspace on this screen. The big warm one
 * is where you are. Click a light to go there.
 */
Item {
    id: root

    required property string output
    required property real t          // life clock, seconds
    readonly property var model: Niri.workspacesOn(output)
    readonly property bool night: Ambience.phase === "night"

    height: Math.max(1, model.length) * Tune.lightSpacing + Tune.lightActive

    // a loose column: each light sits a little off the line
    readonly property var offsets: [1, -2, 3, -1, 2, -3, 1]

    // Count, not the array: delegates survive workspace updates, so size changes animate
    Repeater {
        model: root.model.length

        Item {
            id: light
            required property int index
            readonly property var modelData: root.model[index] ?? ({})
            readonly property bool active: modelData.is_active
            property real size: active ? Tune.lightActive : Tune.lightSize
            readonly property real phase: index * 1.7

            width: size
            height: size
            x: (root.width - size) / 2 + root.offsets[index % root.offsets.length]
               + Math.sin(root.t * 0.5 + phase) * Tune.lightDrift
            y: index * Tune.lightSpacing + (Tune.lightActive - size) / 2
               + Math.cos(root.t * 0.37 + phase * 1.3) * Tune.lightDrift * 1.3

            Behavior on size { NumberAnimation { duration: Tune.settle; easing.type: Easing.OutBack; easing.overshoot: 1.4 } }

            Glow {
                anchors.fill: parent
                scale: hover.hovered ? 1.15 : 1
                Behavior on scale { NumberAnimation { duration: 300; easing.type: Easing.OutBack } }
                opacity: 0.82 + 0.18 * Math.sin(root.t * 1.1 + light.phase * 3)
                core: light.active ? (root.night ? "#fff3cf" : "#fbfde6") : "#faf8e1"
                halo: light.active ? (root.night ? Tune.ember : Tune.sun)
                                   : Qt.rgba(Tune.parch.r, Tune.parch.g, Tune.parch.b, 0.6)
                coreSize: light.active ? 0.13 : 0.15
                Behavior on halo { ColorAnimation { duration: Tune.gradeFade } }
            }

            HoverHandler { id: hover; cursorShape: Qt.PointingHandCursor }
            TapHandler { onTapped: Niri.focusWorkspace(light.modelData.id) }
        }
    }
}
