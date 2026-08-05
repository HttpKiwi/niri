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
    signal toggleExpandRequested()

    onExpandedChanged: {
        expandedStateChanged()
        rebuildDisplayModel()
        notificationsList.contentY = 0
    }

    function toggleExpand() {
        toggleExpandRequested()
    }

    function dismissAll() {
        root._isDismissing = true
        groupDismissTimer.restart()
    }

    function startGroupDismiss() {
        dismissAll()
    }

    property bool groupKeyboardFocused: false
    property int focusedNotificationIndex: -1

    readonly property int maxListHeight: Settings.notificationGroupMaxListHeight
    property var _displayModel: []

    function rebuildDisplayModel() {
        if (!notifications || notifications.length === 0) {
            _displayModel = []
            return
        }
        _displayModel = root.expanded
            ? notifications.slice().reverse()
            : notifications.slice(-1)
    }

    onNotificationsChanged: rebuildDisplayModel()
    Component.onCompleted: rebuildDisplayModel()

    on_DisplayModelChanged: notificationsList.contentY = 0

    onFocusedNotificationIndexChanged: {
        if (focusedNotificationIndex < 0 || !expanded)
            return
        if (notificationsList.contentHeight <= maxListHeight)
            return
        notificationsList.positionViewAtIndex(focusedNotificationIndex, ListView.Contain)
    }

    function arrayIndexForListIndex(listIndex) {
        if (!root.notifications || listIndex < 0)
            return -1
        if (!root.expanded)
            return listIndex === 0 ? root.notifications.length - 1 : -1
        return root.notifications.length - 1 - listIndex
    }

    function dismissNotificationAt(listIndex) {
        const arrayIndex = arrayIndexForListIndex(listIndex)
        if (arrayIndex < 0)
            return

        const notif = root.notifications[arrayIndex]
        if (!notif)
            return

        const item = notificationsList.itemAtIndex(listIndex)
        if (item && typeof item.startDismiss === "function") {
            item.startDismiss()
        } else {
            root.notificationDismissed(root.appName, notif.id)
        }
    }

    function activateNotificationAt(listIndex) {
        const arrayIndex = arrayIndexForListIndex(listIndex)
        if (arrayIndex < 0)
            return

        const notif = root.notifications[arrayIndex]
        if (!notif)
            return

        NotificationService.activate(notif)
        dismissNotificationAt(listIndex)
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
        height: contentColumn.height
        color: Theme.glass(Settings.glassOpacity, Settings.glassTintStrength)
        radius: Settings.cardRadius
        border.width: root.groupKeyboardFocused ? 2 : Settings.cardBorderWidth
        border.color: root.groupKeyboardFocused
            ? Theme.primary
            : (root.hasCritical
                ? Theme.withAlpha(Theme.error, 0.35)
                : Theme.glassBorder(Settings.glassBorderOpacity, Settings.glassTintStrength))
        antialiasing: true
        clip: true

        Column {
            id: contentColumn
            width: parent.width
            spacing: 8

            readonly property int bottomInset: 14

            // Header
            MouseArea {
                id: headerArea
                width: parent.width
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
                width: parent.width - 20
                x: 10
                focus: false
                activeFocusOnTab: false

                height: {
                    if (count === 0)
                        return 0
                    if (!root.expanded)
                        return contentHeight
                    return Math.min(contentHeight, root.maxListHeight)
                }

                model: root._displayModel
                spacing: 6
                clip: true
                interactive: root.expanded && contentHeight > root.maxListHeight
                boundsBehavior: Flickable.StopAtBounds

                remove: Transition {
                    NumberAnimation { property: "opacity"; to: 0; duration: Settings.animationDurationShort; easing.type: Easing.InQuad }
                }

                delegate: NotificationHistoryItem {
                    required property var modelData
                    required property int index

                    width: notificationsList.width
                    notification: modelData
                    appName: root.appName
                    keyboardFocused: root.focusedNotificationIndex >= 0
                        && index === root.focusedNotificationIndex

                    onDismissRequested: {
                        root.notificationDismissed(root.appName, modelData.id)
                    }
                }
            }

            // Group expand control (e.g. "+3 more notifications")
            Item {
                width: parent.width
                height: root.notificationCount > 1 ? 32 : 0
                visible: height > 0

                MouseArea {
                    id: expandControl
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.toggleExpand()

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 6

                        Text {
                            text: root.expanded ? "\ue5ce" : "\ue5cc"
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

            // Bottom inset inside the group card
            Item {
                width: parent.width
                height: contentColumn.bottomInset
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
