pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.config
import qs.core
import qs.components.base

/**
 * OSDWrapper - Vertical volume OSD flush to the left frame, on the blob.
 */
PocketSlidePanel {
    id: root

    required property string screenName

    panelFlag: "osd"
    slideFrom: "left"

    property real volume: Audio.volume
    property bool muted: Audio.muted

    width: Settings.osdWidth
    height: Settings.osdHeight
    implicitWidth: width
    implicitHeight: height

    anchors.left: parent.left
    anchors.verticalCenter: parent.verticalCenter
    anchors.leftMargin: Settings.screenBorderWidth

    function show() {
        if (screenName !== Niri.focused_output_name)
            return;
        panelState.osd = true;
        openPanel();
        timer.restart();
    }

    function hide() {
        closePanel();
    }

    Component.onCompleted: {
        volume = Audio.volume;
        muted = Audio.muted;
    }

    Connections {
        target: Audio
        function onVolumeChanged() {
            root.volume = Audio.volume;
            root.show();
        }
        function onMutedChanged() {
            root.muted = Audio.muted;
            root.show();
        }
    }

    Timer {
        id: timer
        interval: Settings.osdTimeout
        onTriggered: panelState.osd = false
    }

    Rectangle {
        anchors.fill: parent
        radius: width / 2
        color: Theme.withAlpha(Theme.surfaceBase, Settings.surfaceTransparency)
        antialiasing: true
        visible: !Settings.chromeShaderEnabled
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.topMargin: 14
        anchors.bottomMargin: 14
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        spacing: 10

        Text {
            Layout.alignment: Qt.AlignHCenter
            readonly property int volPct: Math.round((root.muted ? 0 : root.volume) * 100)
            text: root.muted ? "\ue04f" : volPct > 50 ? "\ue050" : volPct > 30 ? "\ue04d" : "\ue04e"
            color: root.muted ? Theme.stateMuted : Theme.accent
            font.family: Settings.fontFamilyIcons
            font.pixelSize: Settings.fontSizeIcon

            Behavior on color {
                ColorAnimation { duration: Settings.animationDurationShort }
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.alignment: Qt.AlignHCenter

            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                width: 8
                height: parent.height
                radius: 4
                color: Theme.withAlpha(Theme.textPrimary, 0.12)

                Rectangle {
                    anchors.bottom: parent.bottom
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: parent.width
                    height: parent.height * (root.muted ? 0 : root.volume)
                    radius: parent.radius
                    color: root.muted ? Theme.stateMuted : Theme.accent
                    visible: height > 0.5

                    Behavior on height {
                        NumberAnimation {
                            duration: Settings.animationDurationShort
                            easing.type: Easing.OutQuad
                        }
                    }
                }
            }
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: root.muted ? "M" : Math.round(root.volume * 100) + "%"
            color: root.muted ? Theme.stateMuted : Theme.textPrimary
            font.pixelSize: Settings.fontSizeSmall
            font.weight: Font.Bold

            Behavior on color {
                ColorAnimation { duration: Settings.animationDurationShort }
            }
        }
    }
}
