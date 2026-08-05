import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.config
import qs.core
import qs.components.base

/**
 * ScreenRecordCard - Control center recording controls (gpu-screen-recorder)
 */
Rectangle {
    id: root

    readonly property int pad: 12

    onVisibleChanged: {
        if (visible)
            ScreenRecord.refreshAvailable();
    }

    onEnabledChanged: {
        if (enabled)
            ScreenRecord.refreshAvailable();
    }

    implicitHeight: column.implicitHeight + pad * 2
    width: parent ? parent.width : 380
    radius: Settings.cardRadius
    color: Theme.glass(Math.max(Settings.glassOpacity, 0.58), Settings.glassTintStrength)
    border.color: Theme.glassBorder(Math.max(Settings.glassBorderOpacity, 0.22), Settings.glassTintStrength)
    border.width: Settings.cardBorderWidth
    antialiasing: true

    ColumnLayout {
        id: column
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            margins: root.pad
        }
        spacing: 10

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Rectangle {
                Layout.preferredWidth: 36
                Layout.preferredHeight: 36
                radius: 18
                color: ScreenRecord.pending
                    ? Theme.withAlpha(Theme.accentSecondary, 0.45)
                    : ScreenRecord.recording
                        ? Theme.withAlpha(Theme.error, ScreenRecord.paused ? 0.35 : 0.55)
                        : Theme.withAlpha(Theme.textPrimary, 0.08)

                Text {
                    anchors.centerIn: parent
                    text: ScreenRecord.pending ? "\ue8b8" : "\uef48"
                    color: (ScreenRecord.recording || ScreenRecord.pending) ? Theme.onError : Theme.textPrimary
                    font.family: Settings.fontFamilyIcons
                    font.pixelSize: 18
                }

                SequentialAnimation on opacity {
                    running: (ScreenRecord.recording && !ScreenRecord.paused) || ScreenRecord.pending
                    loops: Animation.Infinite
                    NumberAnimation { from: 1; to: 0.35; duration: 700; easing.type: Easing.InOutQuad }
                    NumberAnimation { from: 0.35; to: 1; duration: 700; easing.type: Easing.InOutQuad }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                Text {
                    Layout.fillWidth: true
                    text: "Screen record"
                    color: Theme.textPrimary
                    font.family: Settings.fontFamilyDefault
                    font.pixelSize: Settings.fontSizeMedium
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                }

                Text {
                    Layout.fillWidth: true
                    text: {
                        if (!ScreenRecord.available)
                            return "Needs gpu-screen-recorder";
                        if (ScreenRecord.pending)
                            return ScreenRecord.statusLabel;
                        if (ScreenRecord.recording)
                            return `${ScreenRecord.statusLabel} · ${ScreenRecord.elapsedText}`;
                        return ScreenRecord.statusLabel;
                    }
                    color: (ScreenRecord.recording || ScreenRecord.pending) ? Theme.error : Theme.textSecondary
                    font.family: Settings.fontFamilyDefault
                    font.pixelSize: Settings.fontSizeSmall
                    elide: Text.ElideRight
                }
            }

            Text {
                visible: ScreenRecord.recording && !ScreenRecord.pending
                text: ScreenRecord.elapsedText
                color: Theme.textPrimary
                font.family: Settings.fontFamilyDefault
                font.pixelSize: Settings.fontSizeTitle
                font.weight: Font.Bold
            }
        }

        // Capture source
        RowLayout {
            Layout.fillWidth: true
            spacing: 6
            enabled: !ScreenRecord.recording && !ScreenRecord.pending
            opacity: enabled ? 1 : 0.5

            ToggleChip {
                Layout.fillWidth: true
                label: "Display"
                checked: ScreenRecord.captureMode === "screen"
                onClicked: ScreenRecord.setCaptureMode("screen")
            }

            ToggleChip {
                Layout.fillWidth: true
                label: "Portal"
                checked: ScreenRecord.captureMode === "portal"
                onClicked: ScreenRecord.setCaptureMode("portal")
            }

            ToggleChip {
                Layout.fillWidth: true
                label: "Region"
                checked: ScreenRecord.captureMode === "region"
                onClicked: ScreenRecord.setCaptureMode("region")
            }
        }

        // Audio toggles
        RowLayout {
            Layout.fillWidth: true
            spacing: 6
            enabled: !ScreenRecord.recording && !ScreenRecord.pending
            opacity: enabled ? 1 : 0.5

            ToggleChip {
                Layout.fillWidth: true
                label: "System audio"
                icon: "\ue050"
                checked: ScreenRecord.includeAudio
                onClicked: ScreenRecord.includeAudio = !ScreenRecord.includeAudio
            }

            ToggleChip {
                Layout.fillWidth: true
                label: "Mic"
                icon: "\ue029"
                checked: ScreenRecord.includeMic
                onClicked: ScreenRecord.includeMic = !ScreenRecord.includeMic
            }
        }

        // Actions
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            ActionButton {
                Layout.fillWidth: true
                visible: !ScreenRecord.recording && !ScreenRecord.pending
                label: "Start"
                icon: "\uef48"
                accent: Theme.accent
                enabled: ScreenRecord.available
                    && (ScreenRecord.captureMode !== "region" || ScreenRecord.regionPickerAvailable)
                onClicked: ScreenRecord.start()
            }

            ActionButton {
                Layout.fillWidth: true
                visible: ScreenRecord.pending
                label: "Cancel"
                icon: "\ue5cd"
                accent: Theme.error
                onClicked: ScreenRecord.stop()
            }

            ActionButton {
                Layout.fillWidth: true
                visible: ScreenRecord.recording && !ScreenRecord.pending
                label: ScreenRecord.paused ? "Resume" : "Pause"
                icon: ScreenRecord.paused ? "\ue037" : "\ue034"
                accent: Theme.accentSecondary
                onClicked: ScreenRecord.togglePause()
            }

            ActionButton {
                Layout.fillWidth: true
                visible: ScreenRecord.recording && !ScreenRecord.pending
                label: "Stop"
                icon: "\ue047"
                accent: Theme.error
                onClicked: ScreenRecord.stop()
            }
        }

        Text {
            Layout.fillWidth: true
            visible: ScreenRecord.errorMessage.length > 0
                || (!ScreenRecord.available)
                || (ScreenRecord.captureMode === "region" && !ScreenRecord.regionPickerAvailable)
            text: {
                if (ScreenRecord.errorMessage.length > 0)
                    return ScreenRecord.errorMessage;
                if (!ScreenRecord.available)
                    return "Install: pacman -S gpu-screen-recorder";
                if (ScreenRecord.captureMode === "region" && !ScreenRecord.regionPickerAvailable)
                    return "Region needs slurp: pacman -S slurp";
                return "";
            }
            color: Theme.error
            font.family: Settings.fontFamilyDefault
            font.pixelSize: Settings.fontSizeCaption
            wrapMode: Text.Wrap
        }

        Text {
            Layout.fillWidth: true
            visible: ScreenRecord.statusMessage.length > 0 && ScreenRecord.errorMessage.length === 0
            text: ScreenRecord.statusMessage
            color: Theme.textSecondary
            font.family: Settings.fontFamilyDefault
            font.pixelSize: Settings.fontSizeCaption
            elide: Text.ElideMiddle
            wrapMode: Text.Wrap
        }
    }

    component ToggleChip: Rectangle {
        id: chip

        property string label: ""
        property string icon: ""
        property bool checked: false
        signal clicked()

        Layout.preferredHeight: 30
        radius: 15
        color: checked
            ? Theme.withAlpha(Theme.accent, 0.28)
            : Theme.withAlpha(Theme.textPrimary, 0.06)
        border.width: 1
        border.color: checked
            ? Theme.withAlpha(Theme.accent, 0.5)
            : Theme.withAlpha(Theme.textPrimary, 0.1)

        Row {
            anchors.centerIn: parent
            spacing: 4

            Text {
                visible: chip.icon.length > 0
                anchors.verticalCenter: parent.verticalCenter
                text: chip.icon
                color: chip.checked ? Theme.accent : Theme.textSecondary
                font.family: Settings.fontFamilyIcons
                font.pixelSize: 14
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: chip.label
                color: chip.checked ? Theme.accent : Theme.textSecondary
                font.family: Settings.fontFamilyDefault
                font.pixelSize: Settings.fontSizeSmall
                font.weight: chip.checked ? Font.DemiBold : Font.Normal
            }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: chip.clicked()
        }
    }

    component ActionButton: Rectangle {
        id: btn

        property string label: ""
        property string icon: ""
        property color accent: Theme.accent
        property bool enabled: true
        signal clicked()

        Layout.preferredHeight: 36
        radius: 18
        opacity: enabled ? 1 : 0.4
        color: btnMouse.containsMouse
            ? Theme.withAlpha(btn.accent, 0.32)
            : Theme.withAlpha(btn.accent, 0.16)
        border.width: 1
        border.color: Theme.withAlpha(btn.accent, 0.4)

        Row {
            anchors.centerIn: parent
            spacing: 6

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: btn.icon
                color: btn.accent
                font.family: Settings.fontFamilyIcons
                font.pixelSize: 16
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: btn.label
                color: Theme.textPrimary
                font.family: Settings.fontFamilyDefault
                font.pixelSize: Settings.fontSizeSmall
                font.weight: Font.DemiBold
            }
        }

        MouseArea {
            id: btnMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: btn.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
            enabled: btn.enabled
            onClicked: btn.clicked()
        }
    }
}
