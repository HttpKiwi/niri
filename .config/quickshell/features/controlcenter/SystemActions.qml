import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.config
import qs.core

/**
 * SystemActions - Session quick access (lock / sleep / caffeine) and power
 */
Rectangle {
    id: root

    property var confirmDialog: null
    property bool keyboardActive: false
    property int focusedIndex: -1
    readonly property int contentPadding: 10
    readonly property int rowHeight: 64

    // Explicit height — RowLayout.implicitHeight is unreliable with Layout.preferredHeight
    implicitHeight: rowHeight * 2 + contentPadding * 2 + Settings.systemActionsSpacing
    height: implicitHeight
    width: parent ? parent.width : 380
    radius: Settings.cardRadius
    color: Theme.glass(Math.max(Settings.glassOpacity, 0.58), Settings.glassTintStrength)
    border.color: Theme.glassBorder(Math.max(Settings.glassBorderOpacity, 0.22), Settings.glassTintStrength)
    border.width: Settings.cardBorderWidth
    antialiasing: true
    clip: false

    readonly property string rebootToWindowsScript: Quickshell.shellDir + "/scripts/reboot-to-windows.sh"

    Column {
        id: columns
        anchors.fill: parent
        anchors.margins: root.contentPadding
        spacing: Settings.systemActionsSpacing

        // Quick session access
        RowLayout {
            id: sessionRow
            width: parent.width
            height: root.rowHeight
            spacing: Settings.systemActionsSpacing

            SystemActionButton {
                Layout.fillWidth: true
                Layout.fillHeight: true
                iconName: "system-lock-screen"
                label: "Lock"
                accentColor: Theme.tertiary
                keyboardFocused: root.keyboardActive && root.focusedIndex === 0
                onClicked: Quickshell.execDetached(["qs", "ipc", "call", "lock", "lockSession"])
            }

            SystemActionButton {
                Layout.fillWidth: true
                Layout.fillHeight: true
                iconName: "system-suspend"
                label: "Sleep"
                accentColor: Theme.accentSecondary
                keyboardFocused: root.keyboardActive && root.focusedIndex === 1
                onClicked: Quickshell.execDetached([
                    "sh", "-c",
                    "qs ipc call lock lockSession && sleep 1 && systemctl suspend -i"
                ])
            }

            SystemActionButton {
                Layout.fillWidth: true
                Layout.fillHeight: true
                iconName: "kteatime"
                fallbackIconName: "preferences-desktop-screensaver"
                label: "Caffeine"
                accentColor: Theme.accent
                active: Caffeine.enabled
                keyboardFocused: root.keyboardActive && root.focusedIndex === 2
                onClicked: Caffeine.toggle()
            }
        }

        // Power (destructive)
        RowLayout {
            id: powerRow
            width: parent.width
            height: root.rowHeight
            spacing: Settings.systemActionsSpacing

            SystemActionButton {
                Layout.fillWidth: true
                Layout.fillHeight: true
                iconName: "system-reboot"
                label: "Reboot"
                accentColor: Theme.tertiary
                isDestructive: true
                keyboardFocused: root.keyboardActive && root.focusedIndex === 3
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
                iconName: "distributor-logo-windows"
                fallbackIconName: "system-reboot"
                label: "Windows"
                accentColor: Theme.accentSecondary
                isDestructive: true
                keyboardFocused: root.keyboardActive && root.focusedIndex === 4
                onClicked: {
                    if (confirmDialog) {
                        confirmDialog.title = "Reboot to Windows";
                        confirmDialog.message = "Reboot directly into Windows?";
                        confirmDialog.confirmLabel = "Windows";
                        confirmDialog.isDestructive = true;
                        confirmDialog.isOpen = true;
                        confirmDialog.confirmed.connect(rebootToWindowsAction);
                        confirmDialog.cancelled.connect(() => {
                            confirmDialog.isOpen = false;
                            confirmDialog.confirmed.disconnect(rebootToWindowsAction);
                        });
                    } else {
                        rebootToWindowsAction();
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
                keyboardFocused: root.keyboardActive && root.focusedIndex === 5
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
    }

    function rebootAction() {
        Quickshell.execDetached(["systemctl", "reboot"]);
    }

    function rebootToWindowsAction() {
        Quickshell.execDetached(["bash", root.rebootToWindowsScript]);
    }

    function shutdownAction() {
        Quickshell.execDetached(["systemctl", "poweroff"]);
    }

    function activateFocused() {
        switch (focusedIndex) {
        case 0:
            Quickshell.execDetached(["qs", "ipc", "call", "lock", "lockSession"]);
            break;
        case 1:
            Quickshell.execDetached([
                "sh", "-c",
                "qs ipc call lock lockSession && sleep 1 && systemctl suspend -i"
            ]);
            break;
        case 2:
            Caffeine.toggle();
            break;
        case 3:
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
            break;
        case 4:
            if (confirmDialog) {
                confirmDialog.title = "Reboot to Windows";
                confirmDialog.message = "Reboot directly into Windows?";
                confirmDialog.confirmLabel = "Windows";
                confirmDialog.isDestructive = true;
                confirmDialog.isOpen = true;
                confirmDialog.confirmed.connect(rebootToWindowsAction);
                confirmDialog.cancelled.connect(() => {
                    confirmDialog.isOpen = false;
                    confirmDialog.confirmed.disconnect(rebootToWindowsAction);
                });
            } else {
                rebootToWindowsAction();
            }
            break;
        case 5:
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
            break;
        }
    }

    component SystemActionButton: Item {
        id: actionBtn

        property string iconName: ""
        property string fallbackIconName: ""
        property string label: ""
        property color accentColor: Theme.accent
        property bool isDestructive: false
        property bool active: false
        property bool keyboardFocused: false
        signal clicked()

        readonly property string resolvedIcon: {
            const primary = Quickshell.iconPath(actionBtn.iconName, "");
            if (primary !== "")
                return primary;
            if (actionBtn.fallbackIconName !== "")
                return Quickshell.iconPath(actionBtn.fallbackIconName, "preferences-system");
            return Quickshell.iconPath("preferences-system", "");
        }

        Rectangle {
            anchors.fill: parent
            radius: Settings.cardRadius
            color: actionBtn.keyboardFocused
                ? Theme.withAlpha(actionBtn.accentColor, 0.14)
                : "transparent"
            border.width: actionBtn.keyboardFocused ? 1 : 0
            border.color: Theme.withAlpha(actionBtn.accentColor, 0.65)
        }

        Column {
            anchors.centerIn: parent
            spacing: 6

            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                width: 36
                height: 36
                radius: 18
                color: {
                    if (actionBtn.active)
                        return Theme.withAlpha(actionBtn.accentColor, 0.35);
                    if (actionBtn.keyboardFocused || actionMouse.hovered)
                        return Theme.withAlpha(actionBtn.accentColor, 0.22);
                    return Theme.withAlpha(Theme.textPrimary, 0.08);
                }
                border.color: Theme.withAlpha(
                    actionBtn.accentColor,
                    actionBtn.active || actionBtn.keyboardFocused ? 0.7 : (actionMouse.hovered ? 0.45 : 0.2)
                )
                border.width: 1

                Behavior on color {
                    ColorAnimation { duration: Settings.animationDurationShort }
                }

                Image {
                    anchors.centerIn: parent
                    source: actionBtn.resolvedIcon
                    sourceSize: Qt.size(18, 18)
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                    visible: source !== ""
                    opacity: (actionBtn.active || actionBtn.keyboardFocused || actionMouse.hovered) ? 1.0 : 0.85
                }
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: actionBtn.label
                color: (actionBtn.active || actionBtn.keyboardFocused || actionMouse.hovered)
                    ? actionBtn.accentColor
                    : Theme.textPrimary
                font.family: Settings.fontFamilyDefault
                font.pixelSize: Settings.fontSizeSmall
                font.weight: actionBtn.active || actionBtn.keyboardFocused ? Font.DemiBold : Font.Medium

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
