import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.components.base
import qs.config
import qs.core

/**
 * NotificationHistoryItem - Individual notification item in history
 * Displays notification summary, body, timestamp, and dismiss button
 */
Item {
    id: root

    required property var notification
    required property string appName
    property bool isSelected: false
    
    signal dismissRequested()

    implicitHeight: Math.max(32, contentColumn.implicitHeight) + Settings.cardPadding * 2
    implicitWidth: parent ? parent.width : Settings.notificationWidth

    // Selection background
    Rectangle {
        anchors.fill: parent
        color: root.isSelected ? (Theme.accentContainer || Theme.surfaceHighlight || "#2a2a2a") : "transparent"
        opacity: root.isSelected ? 0.5 : 0
        
        Behavior on opacity {
            NumberAnimation { duration: Settings.animationDurationShort }
        }
    }

    RowLayout {
        id: contentRow

        anchors.fill: parent
        anchors.margins: Settings.cardPadding
        spacing: 12

        Column {
            id: contentColumn

            Layout.fillWidth: true
            Layout.preferredHeight: implicitHeight
            spacing: 4

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

            // Body (truncated)
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

            // Timestamp with time and day
            Text {
                text: {
                    if (!root.notification || !root.notification.timestamp) return ""
                    try {
                        const date = new Date(root.notification.timestamp)
                        const now = new Date()
                        const diffMs = now - date
                        const diffMins = Math.floor(diffMs / 60000)
                        const diffHours = Math.floor(diffMs / 3600000)
                        const diffDays = Math.floor(diffMs / 86400000)
                        
                        // Format time: HH:MM
                        const hours = date.getHours().toString().padStart(2, '0')
                        const minutes = date.getMinutes().toString().padStart(2, '0')
                        const timeStr = `${hours}:${minutes}`
                        
                        // Format day
                        const dayNames = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
                        const dayName = dayNames[date.getDay()]
                        
                        if (diffMins < 1) return `${timeStr} • Just now`
                        if (diffMins < 60) return `${timeStr} • ${diffMins}m ago`
                        if (diffHours < 24) return `${timeStr} • ${diffHours}h ago`
                        if (diffDays === 0) return `${timeStr} • Today`
                        if (diffDays === 1) return `${timeStr} • Yesterday`
                        if (diffDays < 7) return `${timeStr} • ${dayName}`
                        return `${timeStr} • ${date.toLocaleDateString()}`
                    } catch (e) {
                        return root.notification.timestamp || ""
                    }
                }
                color: Theme.textSecondary
                font.pixelSize: Settings.fontSizeSmall - 2
                font.weight: Font.Normal
                opacity: 0.7
            }
        }

        // App icon
        Image {
            id: notificationImage

            Layout.preferredWidth: 32
            Layout.preferredHeight: 32
            Layout.alignment: Qt.AlignTop

            source: {
                if (!root.notification) return ""
                if (root.notification.appIcon) {
                    const iconPath = Quickshell.iconPath(root.notification.appIcon, "")
                    if (iconPath) return iconPath
                }
                return root.notification.image || ""
            }
            sourceSize: Qt.size(32, 32)
            fillMode: Image.PreserveAspectFit
            smooth: true
            asynchronous: true
            cache: false
            visible: source !== ""
        }

        // Dismiss button
        IconButton {
            Layout.preferredWidth: 20
            Layout.preferredHeight: 20
            Layout.alignment: Qt.AlignTop
            icon: "×"
            iconSize: 14
            buttonSize: 20
            
            onClicked: root.dismissRequested()
        }
    }

    // Separator line
    Rectangle {
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: 1
        color: Theme.cardBorder
        opacity: 0.3
    }
}

