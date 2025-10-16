import QtQuick
import QtQuick.Layouts
import qs.components.base
import qs.config

/**
 * NotificationCard - Notification content card
 * Displays notification information in a card layout
 */
Item {
    id: root

    required property var notification

    signal closeRequested()

    implicitWidth: Settings.notificationWidth
    implicitHeight: contentRow.height + Settings.cardPadding * 2

    Row {
        // Close button

        id: contentRow

        anchors.fill: parent
        anchors.margins: Settings.cardPadding
        spacing: 12

        Column {
            id: contentColumn

            width: parent.width - parent.spacing - (notificationImage.visible ? notificationImage.width + 12 : 0)
            spacing: 4

            // App name
            Text {
                width: parent.width
                text: root.notification ? (root.notification.appName || "Notification") : ""
                color: Theme.textSecondary
                font.pixelSize: Settings.fontSizeSmall
                font.weight: Font.Medium
                elide: Text.ElideRight
            }

            // Summary
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

            // Body
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

            source: root.notification.image || ""
            sourceSize: Qt.size(48, 48)
            visible: source != ""
        }

    }

}
