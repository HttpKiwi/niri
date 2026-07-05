import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import qs.components.base
import qs.config
import qs.core

/**
 * NotificationCard - Notification content card
 * Click activates via NotificationService (live action.invoke() or niri focus)
 */
Item {
    id: root

    required property var notification

    signal closeRequested()
    signal actionInvoked()

    readonly property var liveNotif: {
        const map = NotificationService.liveById
        const id = notification?.id
        return id !== undefined && id !== null ? (map[String(id)] || null) : null
    }
    readonly property var liveActions: liveNotif?.actions ?? []
    readonly property bool hasActions: liveActions.length > 0

    implicitWidth: Settings.notificationWidth
    implicitHeight: contentColumn.implicitHeight + Settings.cardPadding * 2

    ColumnLayout {
        id: contentColumn
        anchors.fill: parent
        anchors.margins: Settings.cardPadding
        spacing: 8

        Row {
            Layout.fillWidth: true
            spacing: 12

            Column {
                id: contentArea
                width: parent.width - parent.spacing - (notificationImage.visible ? notificationImage.width + 12 : 0)
                spacing: 4

                Text {
                    width: parent.width
                    text: root.notification ? (root.notification.appName || "Notification") : ""
                    color: Theme.textSecondary
                    font.pixelSize: Settings.fontSizeSmall
                    font.weight: Font.Medium
                    elide: Text.ElideRight
                }

                Text {
                    text: root.notification ? (root.notification.summary || "") : ""
                    color: Theme.textPrimary
                    font.pixelSize: Settings.fontSizeMedium
                    font.weight: Font.Medium
                    width: parent.width
                    elide: Text.ElideRight
                    maximumLineCount: 1
                    wrapMode: Text.NoWrap
                }

                Text {
                    text: root.notification ? (root.notification.body || "") : ""
                    color: Theme.textSecondary
                    font.pixelSize: Settings.fontSizeSmall
                    width: parent.width
                    elide: Text.ElideRight
                    maximumLineCount: 2
                    wrapMode: Text.WordWrap
                    visible: text.length > 0
                }
            }

            Image {
                id: notificationImage
                source: {
                    if (!root.notification) return "";
                    if (root.notification.appIcon) {
                        const iconPath = Quickshell.iconPath(root.notification.appIcon, "");
                        if (iconPath) return iconPath;
                    }
                    return root.notification.image || "";
                }
                width: 48
                height: 48
                sourceSize: Qt.size(48, 48)
                fillMode: Image.PreserveAspectFit
                smooth: true
                asynchronous: true
                cache: false
                visible: source !== ""
            }
        }

        RowLayout {
            id: actionRow
            visible: root.hasActions && hoverArea.containsMouse
            Layout.fillWidth: true
            spacing: 6

            opacity: visible ? 1 : 0
            Behavior on opacity {
                NumberAnimation { duration: Settings.animationDurationShort }
            }

            Repeater {
                model: root.liveActions

                delegate: Rectangle {
                    required property var modelData
                    required property int index

                    Layout.fillWidth: true
                    implicitHeight: actionText.implicitHeight + 16
                    radius: 8
                    color: actionMouse.containsMouse
                        ? (index === 0 ? Theme.accent : Theme.surfaceHighest)
                        : (index === 0 ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.15) : "transparent")
                    border.width: index === 0 ? 0 : 1
                    border.color: Theme.cardBorder

                    MouseArea {
                        id: actionMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            NotificationService.activateAction(root.notification, index);
                            root.actionInvoked();
                        }
                    }

                    Text {
                        id: actionText
                        anchors.centerIn: parent
                        text: modelData.text || ""
                        color: index === 0 ? Theme.accent : Theme.textPrimary
                        font.pixelSize: 12
                        font.weight: index === 0 ? Font.Medium : Font.Normal
                    }
                }
            }
        }
    }

    MouseArea {
        id: hoverArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        z: -1
        onClicked: {
            NotificationService.activate(root.notification);
            root.actionInvoked();
        }
    }
}
