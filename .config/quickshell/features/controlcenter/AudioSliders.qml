import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire
import qs.config
import qs.core
import qs.components.base

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
                font.family: Settings.fontFamilyDefault
                font.pixelSize: Settings.fontSizeSmall
                elide: Text.ElideRight
                maximumLineCount: 1

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: rowRoot.toggleMute()
                }
            }

            Text {
                Layout.minimumWidth: implicitWidth
                text: rowRoot.muted ? "Muted" : rowRoot.volumePct + "%"
                color: rowRoot.muted ? Theme.textSecondary : Theme.accent
                font.family: Settings.fontFamilyDefault
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
            height: 14
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
                    height: 6
                    radius: 3
                    color: Theme.withAlpha(Theme.textPrimary, 0.1)

                    Rectangle {
                        width: slider.visualPosition * parent.width
                        height: parent.height
                        radius: parent.radius
                        color: Theme.accent
                        visible: width > 0.5
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
            deviceName: Pipewire.defaultAudioSink?.description || "Speaker"
            volumePct: Audio.getVolume()
            enabled: !Audio.muted
            onToggleMute: Audio.toggleMute()
            onVolumeMoved: pct => Audio.setVolume(pct / 100)
        }

        VolumeRow {
            muted: Audio.micMuted
            deviceName: Pipewire.defaultAudioSource?.description || "Microphone"
            volumePct: Audio.getMicVolume()
            enabled: !Audio.micMuted
            onToggleMute: Audio.toggleMicMute()
            onVolumeMoved: pct => Audio.setMicVolume(pct / 100)
        }
    }
}
