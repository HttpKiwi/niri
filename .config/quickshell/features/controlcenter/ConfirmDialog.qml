import QtQuick
import QtQuick.Controls
import Quickshell
import qs.config
import qs.components.base

/**
 * ConfirmDialog - Confirmation dialog for destructive actions
 * Shows a centered modal dialog with title, message, and cancel/confirm buttons
 */
Item {
    id: root

    property string title: "Confirm"
    property string message: "Are you sure?"
    property string confirmLabel: "Confirm"
    property string cancelLabel: "Cancel"
    property bool isDestructive: false
    property bool isOpen: false

    signal confirmed()
    signal cancelled()

    anchors.fill: parent

    Rectangle {
        id: backdrop
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.5)

        MouseArea {
            anchors.fill: parent
            onClicked: root.cancelled()
        }

        opacity: root.isOpen ? 1 : 0
        Behavior on opacity {
            NumberAnimation {
                duration: Settings.animationDurationShort
                easing.type: Easing.OutCubic
            }
        }
    }

    Rectangle {
        id: dialogCard
        width: Settings.confirmDialogWidth
        height: dialogContent.height + Settings.confirmDialogPadding * 2
        radius: Settings.cardRadius
        color: Theme.withAlpha(Theme.surfaceBase, Settings.surfaceTransparency)
        border.color: Theme.borderDefault
        border.width: Settings.cardBorderWidth

        anchors.centerIn: parent

        scale: root.isOpen ? 1 : 0.9
        opacity: root.isOpen ? 1 : 0
        Behavior on scale {
            NumberAnimation {
                duration: Settings.animationDurationShort
                easing.type: Easing.OutCubic
            }
        }
        Behavior on opacity {
            NumberAnimation {
                duration: Settings.animationDurationShort
                easing.type: Easing.OutCubic
            }
        }

        Column {
            id: dialogContent
            width: parent.width - Settings.confirmDialogPadding * 2
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: Settings.confirmDialogPadding
            spacing: 16

            Text {
                width: parent.width
                text: root.title
                color: root.isDestructive ? Theme.error : Theme.textPrimary
                font.family: Settings.fontFamilyDefault
                font.pixelSize: Settings.fontSizeTitle
                font.weight: Font.Bold
                horizontalAlignment: Text.AlignHCenter
            }

            Text {
                width: parent.width
                text: root.message
                color: Theme.textSecondary
                font.family: Settings.fontFamilyDefault
                font.pixelSize: Settings.fontSizeMedium
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
            }

            Row {
                width: parent.width
                spacing: 12
                layoutDirection: Qt.RightToLeft

                Button {
                    width: (parent.width - 12) / 2
                    height: 36
                    text: root.confirmLabel
                    flat: true

                    background: Rectangle {
                        radius: Settings.cardRadius
                        color: root.isDestructive
                            ? (controlButton.btnHovered ? Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.2) : "transparent")
                            : (controlButton.btnHovered ? Theme.accentContainer : "transparent")

                        Behavior on color {
                            ColorAnimation { duration: Settings.animationDurationShort }
                        }
                    }

                    contentItem: Text {
                        text: parent.text
                        color: root.isDestructive
                            ? (controlButton.btnHovered ? Theme.error : Theme.textSecondary)
                            : (controlButton.btnHovered ? Theme.textOnPrimaryContainer : Theme.textSecondary)
                        font.family: Settings.fontFamilyDefault
                        font.pixelSize: Settings.fontSizeMedium
                        font.weight: Font.Medium
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter

                        Behavior on color {
                            ColorAnimation { duration: Settings.animationDurationShort }
                        }
                    }

                    property bool btnHovered: false

                    MouseArea {
                        id: controlButton
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: parent.btnHovered = true
                        onExited: parent.btnHovered = false
                        onClicked: root.confirmed()
                    }
                }

                Button {
                    width: (parent.width - 12) / 2
                    height: 36
                    text: root.cancelLabel
                    flat: true

                    background: Rectangle {
                        radius: Settings.cardRadius
                        color: cancelButton.btnHovered ? Theme.surfaceHighest : "transparent"

                        Behavior on color {
                            ColorAnimation { duration: Settings.animationDurationShort }
                        }
                    }

                    contentItem: Text {
                        text: parent.text
                        color: cancelButton.btnHovered ? Theme.textPrimary : Theme.textSecondary
                        font.family: Settings.fontFamilyDefault
                        font.pixelSize: Settings.fontSizeMedium
                        font.weight: Font.Medium
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter

                        Behavior on color {
                            ColorAnimation { duration: Settings.animationDurationShort }
                        }
                    }

                    property bool btnHovered: false

                    MouseArea {
                        id: cancelButton
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: parent.btnHovered = true
                        onExited: parent.btnHovered = false
                        onClicked: root.cancelled()
                    }
                }
            }
        }
    }

    Keys.onPressed: (event) => {
        if (event.key === Qt.Key_Escape) {
            root.cancelled();
            event.accepted = true;
        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            root.confirmed();
            event.accepted = true;
        }
    }
}
