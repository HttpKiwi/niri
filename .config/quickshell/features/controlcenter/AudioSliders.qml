import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire
import qs.config
import qs.core

/**
 * AudioSliders - Tinted glass card on the blob, knobless pills
 */
Rectangle {
    id: root

    readonly property int pad: 12

    implicitHeight: audioColumn.implicitHeight + pad * 2
    width: parent ? parent.width : 380
    radius: Settings.cardRadius
    color: Theme.glass(Settings.glassOpacity, Settings.glassTintStrength)
    border.color: Theme.glassBorder(Settings.glassBorderOpacity, Settings.glassTintStrength)
    border.width: Settings.cardBorderWidth
    antialiasing: true

    component VolumeRow: Column {
        id: rowRoot

        property bool muted: false
        property string deviceName: ""
        property int volumePct: 0
        property bool enabled: true
        signal volumeMoved(real pct)
        signal toggleMute()

        width: parent.width
        spacing: 6

        RowLayout {
            width: parent.width
            spacing: 8

            Text {
                Layout.fillWidth: true
                text: rowRoot.deviceName
                color: Theme.textSecondary
                font.pixelSize: Settings.fontSizeSmall
                elide: Text.ElideRight

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: rowRoot.toggleMute()
                }
            }

            Text {
                text: rowRoot.muted ? "M" : rowRoot.volumePct + "%"
                color: rowRoot.muted ? Theme.textSecondary : Theme.accent
                font.pixelSize: Settings.fontSizeSmall
                font.weight: Font.DemiBold

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: rowRoot.toggleMute()
                }
            }
        }

        Slider {
            id: slider
            width: parent.width
            height: 18
            padding: 0
            from: 0
            to: 100
            value: rowRoot.volumePct
            enabled: rowRoot.enabled
            opacity: enabled ? 1 : 0.4

            background: Item {
                width: slider.availableWidth
                height: slider.availableHeight

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width
                    height: 10
                    radius: 5
                    color: Theme.withAlpha(Theme.textPrimary, 0.1)

                    Rectangle {
                        width: slider.visualPosition * parent.width
                        height: parent.height
                        radius: parent.radius
                        color: Theme.accent
                        visible: width > 0.5

                        Rectangle {
                            anchors {
                                left: parent.left
                                right: parent.right
                                top: parent.top
                                margins: 2
                            }
                            height: 2
                            radius: 1
                            color: Theme.withAlpha(Theme.textOnPrimary, 0.28)
                            visible: parent.width > 8
                        }
                    }
                }
            }

            handle: Item {
                implicitWidth: 1
                implicitHeight: 1
                visible: false
            }

            onMoved: rowRoot.volumeMoved(value)
        }
    }

    Column {
        id: audioColumn
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            margins: root.pad
        }
        spacing: 10

        VolumeRow {
            muted: Audio.muted
            deviceName: {
                const desc = Pipewire.defaultAudioSink?.description || "Speaker";
                return desc.length > 32 ? desc.substring(0, 32) + "…" : desc;
            }
            volumePct: Audio.getVolume()
            enabled: !Audio.muted
            onToggleMute: Audio.toggleMute()
            onVolumeMoved: pct => Audio.setVolume(pct / 100)
        }

        VolumeRow {
            muted: Audio.micMuted
            deviceName: {
                const desc = Pipewire.defaultAudioSource?.description || "Microphone";
                return desc.length > 32 ? desc.substring(0, 32) + "…" : desc;
            }
            volumePct: Audio.getMicVolume()
            enabled: !Audio.micMuted
            onToggleMute: Audio.toggleMicMute()
            onVolumeMoved: pct => Audio.setMicVolume(pct / 100)
        }
    }
}
