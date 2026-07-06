import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.config
import qs.core

/**
 * SystemActions - Power and session controls on the blob
 */
Rectangle {
    id: root

    property var confirmDialog: null
    readonly property int contentPadding: 10

    implicitHeight: 56 + contentPadding * 2
    width: parent ? parent.width : 380
    radius: Settings.cardRadius
    color: Theme.glass(Settings.glassOpacity, Settings.glassTintStrength)
    border.color: Theme.glassBorder(Settings.glassBorderOpacity, Settings.glassTintStrength)
    border.width: Settings.cardBorderWidth
    antialiasing: true

    RowLayout {
        anchors.fill: parent
        anchors.margins: root.contentPadding
        spacing: Settings.systemActionsSpacing

        SystemActionButton {
            Layout.fillWidth: true
            Layout.fillHeight: true
            iconName: "system-lock-screen"
            label: "Lock"
            accentColor: Theme.tertiary
            onClicked: Quickshell.execDetached(["quickshell", "ipc", "call", "lock", "lockSession"])
        }

        SystemActionButton {
            Layout.fillWidth: true
            Layout.fillHeight: true
            iconName: "system-suspend"
            label: "Sleep"
            accentColor: Theme.accentSecondary
            onClicked: Quickshell.execDetached(["sh", "-c", "quickshell ipc call lock lockSession && sleep 1 && systemctl suspend-then-hibernate -i"])
        }

        SystemActionButton {
            Layout.fillWidth: true
            Layout.fillHeight: true
            iconName: "system-reboot"
            label: "Reboot"
            accentColor: Theme.tertiary
            isDestructive: true
            onClicked: {
                if (confirmDialog) {
                    confirmDialog.title = "Reboot";
                    confirmDialog.message = "Are you sure you want to reboot?";
                    confirmDialog.confirmLabel = "Reboot";
                    confirmDialog.isDestructive = true;
                    confirmDialog.isOpen = true;
                    confirmDialog.confirmed.connect(rebootAction);
                    confirmDialog.cancelled.connect(() => {
                        confirmDialog.isOpen = false;
                        confirmDialog.confirmed.disconnect(rebootAction);
                    });
                }
            }
        }

        SystemActionButton {
            Layout.fillWidth: true
            Layout.fillHeight: true
            iconName: "system-shutdown"
            label: "Shutdown"
            accentColor: Theme.error
            isDestructive: true
            onClicked: {
                if (confirmDialog) {
                    confirmDialog.title = "Shutdown";
                    confirmDialog.message = "Are you sure you want to shut down?";
                    confirmDialog.confirmLabel = "Shutdown";
                    confirmDialog.isDestructive = true;
                    confirmDialog.isOpen = true;
                    confirmDialog.confirmed.connect(shutdownAction);
                    confirmDialog.cancelled.connect(() => {
                        confirmDialog.isOpen = false;
                        confirmDialog.confirmed.disconnect(shutdownAction);
                    });
                }
            }
        }
    }

    function rebootAction() {
        Quickshell.execDetached(["systemctl", "reboot"]);
    }

    function shutdownAction() {
        Quickshell.execDetached(["systemctl", "poweroff"]);
    }

    component SystemActionButton: Item {
        id: actionBtn

        property string iconName: ""
        property string label: ""
        property color accentColor: Theme.accent
        property bool isDestructive: false
        signal clicked()

        Column {
            anchors.centerIn: parent
            spacing: 6

            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                width: 36
                height: 36
                radius: 18
                color: actionMouse.hovered
                    ? Theme.withAlpha(actionBtn.accentColor, 0.22)
                    : Theme.withAlpha(Theme.textPrimary, 0.08)
                border.color: Theme.withAlpha(actionBtn.accentColor, actionMouse.hovered ? 0.45 : 0.2)
                border.width: 1

                Behavior on color {
                    ColorAnimation { duration: Settings.animationDurationShort }
                }

                Image {
                    anchors.centerIn: parent
                    source: Quickshell.iconPath(actionBtn.iconName, "")
                    sourceSize: Qt.size(18, 18)
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                    visible: source !== ""
                    opacity: actionMouse.hovered ? 1.0 : 0.85
                }
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: actionBtn.label
                color: actionMouse.hovered ? actionBtn.accentColor : Theme.textPrimary
                font.family: Settings.fontFamilyDefault
                font.pixelSize: Settings.fontSizeSmall
                font.weight: Font.Medium

                Behavior on color {
                    ColorAnimation { duration: Settings.animationDurationShort }
                }
            }
        }

        MouseArea {
            id: actionMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: actionBtn.clicked()
        }
    }
}
