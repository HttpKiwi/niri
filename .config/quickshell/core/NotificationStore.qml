pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config
import qs.core

/**
 * NotificationStore - Manages persistent storage of notification history
 * Uses Storage (JSON) backend for persistence with dismissal state tracking
 */
QtObject {
    id: root

    // Internal cache for fast reads
    property var _notifications: []

    signal notificationsChanged()

    Component.onCompleted: {
        Storage.notificationsChanged.connect(_loadNotifications)
        _loadNotifications()
    }

    function _loadNotifications() {
        Storage.getAllNotifications(function(data) {
            root._notifications = data || []
            root.notificationsChanged()
        })
    }

    function addNotification(notification) {
        if (!notification || !notification.appName) {
            return
        }
        Storage.addNotification(notification)
    }

    function dismissNotification(notificationId) {
        Storage.dismissNotification(notificationId)
    }

    function removeNotification(notificationId) {
        Storage.removeNotification(notificationId)
    }

    function getNotificationsByApp(appName) {
        return root._notifications.filter(n => n.appName === appName) || []
    }

    function getAppNames() {
        const names = new Set()
        for (const n of root._notifications) {
            names.add(n.appName)
        }
        return Array.from(names)
    }

    function getGroupedNotifications() {
        const groups = {}
        for (const n of root._notifications) {
            if (!n.dismissed) {
                if (!groups[n.appName]) {
                    groups[n.appName] = {
                        appName: n.appName,
                        notifications: [],
                        count: 0,
                        hasCritical: false
                    }
                }
                groups[n.appName].notifications.push(n)
                groups[n.appName].count++
                if (n.urgency === 2) {
                    groups[n.appName].hasCritical = true
                }
            }
        }
        const result = Object.values(groups)
        console.log("NotificationStore.getGroupedNotifications:", result.length, "groups")
        return result
    }

    function clearAll() {
        Storage.clearAll()
    }

    function clearApp(appName) {
        Storage.clearApp(appName)
    }
}
