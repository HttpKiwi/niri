pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import qs.config
import qs.core
import qs.components.base

/**
 * NotificationHistoryItem - Individual notification in history
 * Card style with drag-dismiss, actions, copy, expandable body
 */
Item {
    id: root

    required property var notification
    required property string appName
    property bool _isHovered: false
    property bool _isDismissing: false
    property bool _isDragging: false

    signal dismissRequested()

    readonly property bool isCritical: notification?.urgency === 2
    readonly property bool hasImage: notification?.image !== ""
    readonly property var liveActions: {
        const map = NotificationService.liveById
        const id = notification?.id
        const live = id !== undefined && id !== null ? map[String(id)] : null
        return live?.actions ?? []
    }
    property bool bodyExpanded: false
    property bool _copied: false

    implicitHeight: contentItem.implicitHeight

    transform: Translate {
        id: dismissTransform
        x: root._isDismissing ? 250 : 0
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

    Rectangle {
        id: contentItem
        width: parent.width
        color: Theme.glass(Math.min(Settings.glassOpacity + 0.12, 0.7), Settings.glassTintStrength)
        radius: Settings.cardRadius
        border.width: Settings.cardBorderWidth
        border.color: root.isCritical
            ? Theme.withAlpha(Theme.error, 0.35)
            : Theme.glassBorder(Settings.glassBorderOpacity, Settings.glassTintStrength)
        antialiasing: true

        property real padding: 12
        implicitHeight: notificationContent.implicitHeight + padding * 2

        Behavior on implicitHeight {
            NumberAnimation {
                duration: Settings.animationDurationMedium
                easing.type: Easing.OutQuad
            }
        }

        ColumnLayout {
            id: notificationContent
            anchors.fill: parent
            anchors.margins: contentItem.padding
            spacing: 10

            // Header row
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                // Critical indicator
                Rectangle {
                    visible: root.isCritical
                    Layout.preferredWidth: 6
                    Layout.preferredHeight: 6
                    radius: 3
                    color: Theme.error

                    SequentialAnimation on opacity {
                        running: root.isCritical
                        loops: Animation.Infinite
                        NumberAnimation { to: 0.4; duration: 600 }
                        NumberAnimation { to: 1; duration: 600 }
                    }
                }

                // App name
                Text {
                    Layout.fillWidth: true
                    text: root.appName || "Unknown"
                    color: Theme.textSecondary
                    font.pixelSize: 11
                    font.weight: Font.Normal
                    elide: Text.ElideRight
                }

                // Timestamp + expand chevron
                MouseArea {
                    Layout.alignment: Qt.AlignVCenter
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    implicitWidth: timeRow.implicitWidth
                    implicitHeight: 20
                    onClicked: root.bodyExpanded = !root.bodyExpanded

                    Row {
                        id: timeRow
                        spacing: 4
                        anchors.centerIn: parent

                        Text {
                            id: timeText
                            text: {
                                if (!root.notification || !root.notification.timestamp) return ""
                                try {
                                    const date = new Date(root.notification.timestamp)
                                    const now = new Date()
                                    const diffMs = now - date
                                    const diffMins = Math.floor(diffMs / 60000)
                                    const diffHours = Math.floor(diffMs / 3600000)
                                    const diffDays = Math.floor(diffMs / 86400000)

                                    const hours = date.getHours().toString().padStart(2, '0')
                                    const minutes = date.getMinutes().toString().padStart(2, '0')
                                    const timeStr = `${hours}:${minutes}`

                                    if (diffMins < 1) return `${timeStr}`
                                    if (diffMins < 60) return `${diffMins}m ago`
                                    if (diffHours < 24) return `${diffHours}h ago`
                                    if (diffDays === 1) return `Yesterday`
                                    return `${date.toLocaleDateString()}`
                                } catch (e) {
                                    return ""
                                }
                            }
                            color: Theme.textSecondary
                            font.pixelSize: 11
                        }

                        Text {
                            id: chevron
                            text: root.bodyExpanded ? "\ue5ce" : "\ue5cc"
                            color: Theme.textSecondary
                            font.family: Settings.fontFamilyIcons
                            font.pixelSize: 10

                            Behavior on rotation {
                                NumberAnimation {
                                    duration: Settings.animationDurationShort
                                    easing.type: Easing.OutQuad
                                }
                            }
                        }
                    }
                }

                // Copy button
                IconButton {
                    Layout.alignment: Qt.AlignVCenter
                    icon: root._copied ? "\ue5ca" : "\ue14d"
                    iconSize: 14
                    buttonSize: 20
                    opacity: root._isHovered ? 1 : 0

                    Behavior on opacity {
                        NumberAnimation { duration: Settings.animationDurationShort }
                    }

                    onClicked: {
                        copyProcess.command = ["wl-copy", root.notification?.body || ""]
                        copyProcess.running = true
                    }
                }

                Process {
                    id: copyProcess
                    onExited: (code, status) => {
                        if (code === 0) {
                            root._copied = true
                            copyTimer.restart()
                        }
                    }
                }

                Timer {
                    id: copyTimer
                    interval: 1500
                    onTriggered: root._copied = false
                }

                // Dismiss button
                IconButton {
                    Layout.alignment: Qt.AlignVCenter
                    icon: "\ue5cd"
                    iconSize: 16
                    buttonSize: 20
                    opacity: root._isHovered ? 1 : 0

                    Behavior on opacity {
                        NumberAnimation { duration: Settings.animationDurationShort }
                    }

                    onClicked: root.startDismiss()
                }
            }

            // Content area with optional image
            Item {
                Layout.fillWidth: true
                implicitHeight: Math.max(contentColumn.implicitHeight, imageLoader.active ? imageLoader.height : 0)

                Loader {
                    id: imageLoader
                    anchors.top: parent.top
                    anchors.left: parent.left
                    active: root.hasImage
                    sourceComponent: Image {
                        width: 48
                        height: 48
                        sourceSize: Qt.size(48, 48)
                        source: root.notification?.image || ""
                        fillMode: Image.PreserveAspectFit
                        smooth: true
                        asynchronous: true
                    }
                }

                ColumnLayout {
                    id: contentColumn
                    anchors.top: parent.top
                    anchors.right: parent.right
                    spacing: 4
                    anchors.left: imageLoader.active ? imageLoader.right : parent.left
                    anchors.leftMargin: imageLoader.active ? 12 : 0

                    // Summary
                    Text {
                        Layout.fillWidth: true
                        text: root.notification ? (root.notification.summary || "") : ""
                        color: root.isCritical ? Theme.error : Theme.textPrimary
                        font.pixelSize: 13
                        font.weight: root.isCritical ? Font.Bold : Font.Medium
                        elide: Text.ElideRight
                        wrapMode: Text.NoWrap
                    }

                    // Body
                    Text {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        text: {
                            const body = root.notification?.body || ""
                            if (!body) return ""
                            return body.replace(/\n/g, "<br/>")
                        }
                        color: Theme.textSecondary
                        font.pixelSize: 12
                        wrapMode: Text.Wrap
                        maximumLineCount: root.bodyExpanded ? 100 : 2
                        elide: Text.ElideRight
                        textFormat: Text.StyledText
                        onLinkActivated: (link) => Qt.openUrlExternally(link)
                    }
                }
            }

            // Action buttons (live NotificationAction from NotificationService)
            RowLayout {
                visible: root.liveActions.length > 0
                Layout.fillWidth: true
                spacing: 6

                Repeater {
                    model: root.liveActions

                    delegate: Rectangle {
                        required property var modelData
                        required property int index

                        Layout.fillWidth: true
                        implicitHeight: actionText.implicitHeight + 16
                        radius: 8
                        color: mouseArea.containsMouse ? (index === 0 ? Theme.accent : Theme.surfaceHighest) : (index === 0 ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.15) : "transparent")
                        border.width: index === 0 ? 0 : 1
                        border.color: Theme.cardBorder

                        MouseArea {
                            id: mouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                NotificationService.activateAction(root.notification, index)
                                root.startDismiss()
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
    }

    MouseArea {
        z: -1
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        drag {
            target: contentItem
            axis: Drag.XAxis
            minimumX: 0
            onActiveChanged: {
                if (!drag.active) {
                    if (contentItem.x > 100) {
                        root.startDismiss()
                    } else {
                        contentItem.x = 0
                    }
                }
            }
        }

        onClicked: {
            // Skip if this was a drag-dismiss gesture
            if (Math.abs(contentItem.x) > 10)
                return;
            NotificationService.activate(root.notification);
            root.startDismiss();
        }

        onEntered: root._isHovered = true
        onExited: {
            root._isHovered = false
            if (!contentItem.Drag.active) {
                contentItem.x = 0
            }
        }
    }

    function startDismiss() {
        if (root._isDismissing) return
        root._isDismissing = true
        dismissTimer.restart()
    }

    Timer {
        id: dismissTimer
        interval: Settings.animationDurationMedium
        repeat: false
        onTriggered: {
            root.dismissRequested()
        }
    }
}
