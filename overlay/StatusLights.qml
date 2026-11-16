import QtQuick
import qs.config
import qs.services

/**
 * StatusLights - small lights above the island seed: volume, headset battery,
 * resources. White when calm, red when loaded (battery: red when low). Hover
 * one for its number.
 */
Item {
    id: root

    required property real t
    readonly property bool hovered: hoverIndex >= 0
    property int hoverIndex: -1

    // 0 = calm .. 1 = alarm
    function alarm(v) { return Math.max(0, Math.min(1, (v - 0.5) / 0.4)); }
    readonly property var entries: {
        const out = [{ alarm: Audio.muted ? 0 : alarm(Audio.volume), dim: Audio.muted,
                       text: Audio.muted ? "Volume muted" : "Volume " + Math.round(Audio.volume * 100) + "%" }];
        if (Status.battery >= 0)
            out.push({ alarm: alarm(1 - Status.battery / 100), dim: false, text: "Headset " + Status.battery + "%" });
        out.push({ alarm: alarm(Math.max(Status.cpu, Status.ram)), dim: false,
                   text: "CPU " + Math.round(Status.cpu * 100) + "% · RAM " + Math.round(Status.ram * 100) + "%" });
        return out;
    }

    width: Tune.stripSpan
    height: entries.length * Tune.statusSpacing

    Repeater {
        model: root.entries

        Item {
            id: light
            required property var modelData
            required property int index
            readonly property color tint: Qt.rgba(1 - 0.08 * modelData.alarm, 0.98 - 0.62 * modelData.alarm,
                                                  0.9 - 0.62 * modelData.alarm, 1)
            width: root.width
            height: Tune.statusSpacing
            y: index * Tune.statusSpacing

            Glow {
                width: Tune.statusSize; height: width
                x: (root.width - width) / 2 + Math.sin(root.t * 0.5 + light.index * 2) * 0.8
                y: (light.height - height) / 2 + Math.cos(root.t * 0.4 + light.index) * 0.8
                scale: hover.hovered ? 1.25 : 1
                Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                opacity: light.modelData.dim ? 0.3 : 0.9
                core: light.tint
                halo: light.tint
                coreSize: 0.2
            }
            HoverHandler {
                id: hover
                onHoveredChanged: {
                    if (hovered) root.hoverIndex = light.index;
                    else if (root.hoverIndex === light.index) root.hoverIndex = -1;
                }
            }

            // the number, beside the light
            Rectangle {
                x: root.width + 2
                anchors.verticalCenter: parent.verticalCenter
                width: label.implicitWidth + 20
                height: 26
                radius: 13
                color: Qt.rgba(0.1, 0.14, 0.12, 0.94)
                opacity: hover.hovered ? 1 : 0
                visible: opacity > 0
                Behavior on opacity { NumberAnimation { duration: 180 } }
                Text {
                    id: label
                    anchors.centerIn: parent
                    text: light.modelData.text
                    font.family: Tune.uiFont
                    font.pixelSize: 12
                    color: Tune.parch
                }
            }
        }
    }
}
