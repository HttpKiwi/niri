pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.config
import qs.core
import qs.components.base

/**
 * NotificationHistoryGroup - App group component for notification history
 * Card style with swipe-to-dismiss, ListView transitions, critical indicator
 */
Item {
    id: root

    required property string appName
    required property var notifications
    property bool hasCritical: false
    property bool _isDismissing: false
    property real _dragX: 0

    signal notificationDismissed(string appName, int notificationId)
    signal groupDismissed(string appName)

    implicitHeight: contentItem.height
    implicitWidth: parent ? parent.width : Settings.notificationWidth

    property bool expanded: false
    readonly property int notificationCount: notifications ? notifications.length : 0

    signal expandedStateChanged()

    onExpandedChanged: expandedStateChanged()

    function toggleExpand() {
        expanded = !expanded
    }

    function dismissAll() {
        root._isDismissing = true
        groupDismissTimer.restart()
    }

    // Swipe-to-dismiss via drag
    MouseArea {
        id: dragArea
        anchors.fill: parent
        hoverEnabled: false
        drag {
            target: contentItem
            axis: Drag.XAxis
            minimumX: 0
            onActiveChanged: {
                if (!drag.active) {
                    if (Math.abs(contentItem.x) > 80) {
                        root.dismissAll()
                    } else {
                        contentItem.x = 0
                    }
                }
            }
        }

        onClicked: (mouse) => {
            if (mouse.button === Qt.MiddleButton) {
                root.dismissAll()
            }
        }
    }

    // Swipe progress indicator
    Rectangle {
        visible: Math.abs(contentItem.x) > 20
        anchors.right: contentItem.x < 0 ? parent.right : undefined
        anchors.left: contentItem.x > 0 ? parent.left : undefined
        anchors.verticalCenter: parent.verticalCenter
        width: 36
        height: 36
        radius: 18
        color: Theme.error
        opacity: Math.min(Math.abs(contentItem.x) / 80, 1) * 0.8

        Text {
            anchors.centerIn: parent
            text: "\ue5cd"
            color: Theme.textOnPrimary
            font.family: Settings.fontFamilyIcons
            font.pixelSize: 18
        }
    }

    // Dismiss animation
    transform: Translate {
        x: root._isDismissing ? 300 : 0
        Behavior on x {
            NumberAnimation {
                duration: Settings.animationDurationMedium
                easing.type: Settings.easingAccelerate
            }
        }
    }

    opacity: root._isDismissing ? 0 : 1
    Behavior on opacity {
        NumberAnimation {
            duration: Settings.animationDurationMedium
            easing.type: Settings.easingAccelerate
        }
    }

    // Card container — tinted glass over the blob
    Rectangle {
        id: contentItem
        width: parent.width
        height: computedHeight
        color: Theme.glass(Settings.glassOpacity, Settings.glassTintStrength)
        radius: Settings.cardRadius
        border.width: Settings.cardBorderWidth
        border.color: root.hasCritical
            ? Theme.withAlpha(Theme.error, 0.35)
            : Theme.glassBorder(Settings.glassBorderOpacity, Settings.glassTintStrength)
        antialiasing: true
        clip: true

        property real computedHeight: headerRow.height + notificationsList.contentHeight + (expandControl.visible ? expandControl.height + 20 : 24)

        Behavior on height {
            NumberAnimation {
                duration: Settings.animationDurationMedium
                easing.type: Easing.OutQuad
            }
        }

        // Header
        MouseArea {
            id: headerArea
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: headerRow.height
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor

            onClicked: root.toggleExpand()

            RowLayout {
                id: headerRow
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: 14
                anchors.rightMargin: 14
                height: 40
                spacing: 8

                // App icon
                Image {
                    Layout.preferredWidth: 20
                    Layout.preferredHeight: 20
                    Layout.alignment: Qt.AlignVCenter

                    source: {
                        if (notifications && notifications.length > 0 && notifications[0].appIcon && notifications[0].appIcon.length > 0) {
                            const iconPath = Quickshell.iconPath(notifications[0].appIcon, "")
                            if (iconPath) return iconPath
                        }
                        return ""
                    }
                    sourceSize: Qt.size(20, 20)
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                    asynchronous: true
                    visible: source !== ""
                }

                // Critical indicator
                Rectangle {
                    visible: root.hasCritical
                    Layout.preferredWidth: 6
                    Layout.preferredHeight: 6
                    radius: 3
                    color: Theme.error

                    SequentialAnimation on opacity {
                        running: root.hasCritical
                        loops: Animation.Infinite
                        NumberAnimation { to: 0.4; duration: 600 }
                        NumberAnimation { to: 1; duration: 600 }
                    }
                }

                // App name
                Text {
                    Layout.fillWidth: true
                    text: root.appName || "Unknown"
                    color: root.hasCritical ? Theme.error : Theme.textPrimary
                    font.family: Settings.fontFamilyDefault
                    font.pixelSize: Settings.fontSizeLarge
                    font.weight: root.hasCritical ? Font.Bold : Font.Medium
                    elide: Text.ElideRight
                }

                // Count badge
                Rectangle {
                    Layout.preferredWidth: countText.width + 8
                    Layout.preferredHeight: 18
                    Layout.alignment: Qt.AlignVCenter
                    radius: 9
                    color: Theme.accentContainer
                    visible: root.notificationCount > 1

                    Text {
                        id: countText
                        anchors.centerIn: parent
                        text: root.notificationCount.toString()
                        color: Theme.textOnPrimaryContainer
                        font.family: Settings.fontFamilyDefault
                        font.pixelSize: Settings.fontSizeCaption
                        font.weight: Font.Medium
                    }
                }

                // Dismiss all button (hover-reveal)
                IconButton {
                    Layout.alignment: Qt.AlignVCenter
                    icon: "\ue5cd"
                    iconSize: 16
                    buttonSize: 22
                    opacity: headerArea.containsMouse ? 1 : 0

                    Behavior on opacity {
                        NumberAnimation { duration: Settings.animationDurationShort }
                    }

                    onClicked: root.dismissAll()
                }

                // Expand chevron
                Text {
                    Layout.preferredWidth: 16
                    Layout.preferredHeight: 16
                    Layout.alignment: Qt.AlignVCenter
                    text: root.expanded ? "\ue5ce" : "\ue5cc"
                    color: Theme.textSecondary
                    font.family: Settings.fontFamilyIcons
                    font.pixelSize: 11
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter

                    Behavior on rotation {
                        NumberAnimation {
                            duration: Settings.animationDurationShort
                            easing.type: Easing.OutQuad
                        }
                    }
                }
            }
        }

        // Notifications list
        ListView {
            id: notificationsList
            anchors.top: headerArea.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.topMargin: 8
            anchors.leftMargin: 10
            anchors.rightMargin: 10

            width: parent.width - 20
            visible: height > 0
            height: contentHeight
            model: root.expanded ? root.notifications.slice().reverse() : root.notifications.slice(-1)
            cacheBuffer: 3
            spacing: 6
            clip: true
            interactive: false

            add: Transition {
                ParallelAnimation {
                    NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Settings.animationDurationMedium; easing.type: Easing.OutQuad }
                    NumberAnimation { property: "scale"; from: 0.95; to: 1; duration: Settings.animationDurationMedium; easing.type: Easing.OutQuad }
                }
            }

            remove: Transition {
                ParallelAnimation {
                    NumberAnimation { property: "opacity"; to: 0; duration: Settings.animationDurationMedium; easing.type: Easing.InQuad }
                    NumberAnimation { property: "x"; to: 50; duration: Settings.animationDurationMedium; easing.type: Easing.InQuad }
                }
            }

            displaced: Transition {
                NumberAnimation { properties: "x,y"; duration: Settings.animationDurationMedium; easing.type: Easing.OutQuad }
            }

            Behavior on height {
                NumberAnimation {
                    duration: Settings.animationDurationMedium
                    easing.type: Easing.OutQuad
                }
            }

            delegate: NotificationHistoryItem {
                required property var modelData
                required property int index

                width: notificationsList.width
                notification: modelData
                appName: root.appName

                onDismissRequested: {
                    root.notificationDismissed(root.appName, modelData.id)
                }
            }
        }

        // Group expand control (e.g. "+3 more notifications")
        MouseArea {
            id: expandControl
            anchors.top: notificationsList.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.topMargin: 4
            anchors.bottomMargin: 8
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            visible: root.notificationCount > 1
            implicitHeight: 28
            cursorShape: Qt.PointingHandCursor
            onClicked: root.toggleExpand()

            RowLayout {
                anchors.centerIn: parent
                spacing: 6

                Text {
                    text: "\ue5ce"
                    color: Theme.accent
                    font.family: Settings.fontFamilyIcons
                    font.pixelSize: 10
                }

                Text {
                    text: root.expanded ? "See fewer" : `+${root.notificationCount - 1} more notifications`
                    color: Theme.accent
                    font.family: Settings.fontFamilyDefault
                    font.pixelSize: Settings.fontSizeSmall
                    font.weight: Font.Medium
                }
            }
        }
    }

    Timer {
        id: groupDismissTimer
        interval: Settings.animationDurationMedium
        repeat: false
        onTriggered: {
            root.groupDismissed(root.appName)
        }
    }
}
