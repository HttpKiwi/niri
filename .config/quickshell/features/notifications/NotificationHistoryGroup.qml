import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.components.base
import qs.config
import qs.core

/**
 * NotificationHistoryGroup - App group component for notification history
 * Displays app icon, name, count, and expandable list of notifications
 */
Item {
    id: root

    required property string appName
    required property var notifications
    property bool isSelected: false
    property int selectedNotificationIndex: -1
    
    signal notificationDismissed(string appName, int notificationId)
    signal toggleExpandRequested()

    implicitHeight: contentColumn.height
    implicitWidth: parent ? parent.width : Settings.notificationWidth

    property bool expanded: true
    
    signal expandedStateChanged()
    
    onExpandedChanged: {
        expandedStateChanged()
    }
    
    function toggleExpand() {
        expanded = !expanded
        expandedStateChanged()
    }

    Column {
        id: contentColumn
        objectName: "contentColumn"

        width: parent.width
        spacing: 8

        // Header - clickable to expand/collapse
        MouseArea {
            width: parent.width
            height: headerRow.implicitHeight + Settings.cardPadding * 2
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            
            onClicked: {
                root.expanded = !root.expanded
                root.expandedStateChanged()
            }

            Rectangle {
                anchors.fill: parent
                color: {
                    if (root.isSelected) {
                        return Theme.accentContainer || Theme.surfaceHighlight || "#2a2a2a"
                    }
                    return parent.containsMouse ? (Theme.surfaceContainer || "#1e1e1e") : "transparent"
                }
                
                Behavior on color {
                    ColorAnimation { duration: Settings.animationDurationShort }
                }
            }

            RowLayout {
                id: headerRow

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: Settings.cardPadding
                anchors.rightMargin: Settings.cardPadding
                spacing: 12

                // App icon
                Image {
                    Layout.preferredWidth: 24
                    Layout.preferredHeight: 24
                    Layout.alignment: Qt.AlignVCenter

                    source: {
                        if (notifications && notifications.length > 0 && notifications[0].appIcon) {
                            const iconPath = Quickshell.iconPath(notifications[0].appIcon, "")
                            if (iconPath) return iconPath
                        }
                        return ""
                    }
                    sourceSize: Qt.size(24, 24)
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                    asynchronous: true
                    cache: false
                    visible: source !== ""
                }

                // App name
                Text {
                    Layout.fillWidth: true
                    text: root.appName || "Unknown"
                    color: Theme.textPrimary
                    font.pixelSize: Settings.fontSizeMedium
                    font.weight: Font.Medium
                    elide: Text.ElideRight
                }

                // Notification count badge
                Rectangle {
                    Layout.preferredWidth: countText.width + 8
                    Layout.preferredHeight: 20
                    Layout.alignment: Qt.AlignVCenter
                    radius: 10
                    color: Theme.accentContainer
                    visible: (notifications && notifications.length > 0) ? true : false

                    Text {
                        id: countText
                        anchors.centerIn: parent
                        text: notifications ? notifications.length.toString() : "0"
                        color: Theme.textOnPrimaryContainer
                        font.pixelSize: Settings.fontSizeSmall - 2
                        font.weight: Font.Medium
                    }
                }

                // Expand/collapse icon
                Text {
                    Layout.preferredWidth: 16
                    Layout.preferredHeight: 16
                    Layout.alignment: Qt.AlignVCenter
                    text: root.expanded ? "▼" : "▶"
                    color: Theme.textSecondary
                    font.pixelSize: 10
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    
                    Behavior on rotation {
                        NumberAnimation { duration: Settings.animationDurationShort }
                    }
                }
            }
        }

        // Notifications list (expandable) - using ListView for virtualization
        ListView {
            id: notificationsList

            width: parent.width
            // Keep visible during animation for smooth collapse
            visible: height > 0
            // Calculate height based on item count and item height (approximately 84px per item)
            // ListView will only create visible items, saving memory
            height: root.expanded ? Math.min((root.notifications?.length || 0) * 84, 600) : 0
            model: root.expanded ? (root.notifications || []) : []
            cacheBuffer: 3  // Keep 3 items above/below viewport for smooth scrolling
            spacing: 4
            clip: true
            interactive: false  // Disable internal scrolling since parent ScrollView handles it

            Behavior on height {
                NumberAnimation {
                    duration: Settings.animationDurationMedium
                    easing.type: Settings.easingStandard
                }
            }

            delegate: NotificationHistoryItem {
                required property var modelData
                required property int index
                
                objectName: "notificationItem" + index
                width: notificationsList.width
                notification: modelData
                appName: root.appName
                isSelected: root.selectedNotificationIndex === index

                onDismissRequested: {
                    root.notificationDismissed(root.appName, modelData.id)
                }
            }
        }
    }

    // Separator line
    Rectangle {
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: 1
        color: Theme.cardBorder
        opacity: 0.2
    }
}

