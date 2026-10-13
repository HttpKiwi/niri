import QtQuick
import QtQuick.Layouts
import qs.config
import qs.core

/**
 * NotificationActions - Action buttons for a notification (popup card and history item).
 * Prefers the live NotificationAction list; falls back to the stored copy.
 */
RowLayout {
    id: root

    required property var notification
    property int buttonPadding: 12
    property int fontSize: 12
    signal invoked()

    readonly property var actions: NotificationService.actionsFor(notification)

    visible: actions.length > 0
    Layout.fillWidth: true
    spacing: 6

    Repeater {
        model: root.actions

        delegate: Rectangle {
            required property var modelData
            required property int index

            Layout.fillWidth: true
            implicitHeight: actionText.implicitHeight + root.buttonPadding
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
                    root.invoked();
                }
            }

            Text {
                id: actionText
                anchors.centerIn: parent
                width: parent.width - 12
                horizontalAlignment: Text.AlignHCenter
                text: modelData.text || ""
                color: index === 0 ? Theme.accent : Theme.textPrimary
                font.family: Settings.fontFamilyDefault
                font.pixelSize: root.fontSize
                font.weight: index === 0 ? Font.Medium : Font.Normal
                wrapMode: Text.WordWrap
                maximumLineCount: 2
                elide: Text.ElideRight
            }
        }
    }
}
