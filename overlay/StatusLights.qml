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
        const out = [{ volume: true, alarm: 0, level: Audio.muted ? 0.12 : 0.25 + 0.75 * Math.min(1, Audio.volume),
                       text: Audio.muted ? "Volume muted" : "Volume " + Math.round(Audio.volume * 100) + "%" }];
        if (Status.battery >= 0)
            out.push({ alarm: alarm(1 - Status.battery / 100), level: 0.9, text: "Headset " + Status.battery + "%" });
        out.push({ alarm: alarm(Math.max(Status.cpu, Status.ram)), level: 0.9,
                   text: "CPU " + Math.round(Status.cpu * 100) + "% · RAM " + Math.round(Status.ram * 100) + "%" });
        return out;
    }

    width: Tune.stripSpan
    height: entries.length * Tune.statusSpacing

    Repeater {
        model: root.entries.length

        Item {
            id: light
            required property int index
            // by index, so delegates (and their hover state) survive value updates
            readonly property var modelData: root.entries[index] ?? ({})
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
                opacity: light.modelData.level
                Behavior on opacity { NumberAnimation { duration: 200 } }
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

            // scroll the volume light to change the volume
            MouseArea {
                anchors.fill: parent
                enabled: light.modelData.volume === true
                acceptedButtons: Qt.NoButton
                onWheel: wheel => wheel.angleDelta.y > 0 ? Audio.raiseVolume() : Audio.lowerVolume()
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
