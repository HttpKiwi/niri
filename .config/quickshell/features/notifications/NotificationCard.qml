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
    readonly property var liveActions: liveNotif?.actions ?? notification?.actions ?? []
    readonly property bool hasActions: liveActions.length > 0

    implicitWidth: Settings.notificationWidth
    implicitHeight: Math.max(
        Settings.notificationMinHeight,
        contentColumn.implicitHeight + Settings.cardPadding * 2
    )

    ColumnLayout {
        id: contentColumn
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            margins: Settings.cardPadding
        }
        spacing: 8

        Item {
            Layout.fillWidth: true
            implicitHeight: contentRow.implicitHeight

            Row {
                id: contentRow
                width: parent.width
                spacing: 12

                Column {
                id: contentArea
                width: parent.width - parent.spacing - (notificationImage.visible ? notificationImage.width + 12 : 0)
                spacing: 4

                Text {
                    width: parent.width
                    text: root.notification ? (root.notification.appName || "Notification") : ""
                    color: Theme.textSecondary
                    font.family: Settings.fontFamilyDefault
                    font.pixelSize: Settings.fontSizeSmall
                    font.weight: Font.Medium
                    elide: Text.ElideRight
                }

                Text {
                    text: root.notification ? (root.notification.summary || "") : ""
                    color: Theme.textPrimary
                    font.family: Settings.fontFamilyDefault
                    font.pixelSize: Settings.fontSizeMedium
                    font.weight: Font.Medium
                    width: parent.width
                    elide: Text.ElideRight
                    maximumLineCount: 2
                    wrapMode: Text.WordWrap
                }

                Text {
                    width: parent.width
                    text: root.notification ? (root.notification.body || "") : ""
                    color: Theme.textSecondary
                    font.family: Settings.fontFamilyDefault
                    font.pixelSize: Settings.fontSizeSmall
                    textFormat: Text.StyledText
                    wrapMode: Text.WordWrap
                    maximumLineCount: 3
                    elide: Text.ElideRight
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

            MouseArea {
                anchors.fill: parent
                hoverEnabled: false
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    NotificationService.activate(root.notification);
                    root.actionInvoked();
                }
            }
        }

        RowLayout {
            id: actionRow
            visible: root.hasActions
            Layout.fillWidth: true
            spacing: 6
            z: 2

            Repeater {
                model: root.liveActions

                delegate: Rectangle {
                    required property var modelData
                    required property int index

                    Layout.fillWidth: true
                    implicitHeight: actionText.implicitHeight + 12
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
                        width: parent.width - 12
                        horizontalAlignment: Text.AlignHCenter
                        text: modelData.text || ""
                        color: index === 0 ? Theme.accent : Theme.textPrimary
                        font.pixelSize: 12
                        font.weight: index === 0 ? Font.Medium : Font.Normal
                        wrapMode: Text.WordWrap
                        maximumLineCount: 2
                        elide: Text.ElideRight
                    }
                }
            }
        }
    }
}
