pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Services.Notifications
import QtQuick

/**
 * Notification Service - Handles D-Bus desktop notifications
 * Listens for notifications via org.freedesktop.Notifications
 */
Item {
    id: root

    // Notification server to listen for D-Bus notifications
    NotificationServer {
        id: notificationServer

        // Handle incoming notifications
        onNotification: function(notification) {
            console.log("Received notification:", notification.summary, notification.body)
            
            // Mark notification as tracked to prevent auto-dismissal
            notification.tracked = true
            
            // Emit signal immediately - manager handles queueing
            root.notificationReceived(notification)
        }
    }

    // Signal emitted when a notification should be displayed
    signal notificationReceived(var notification)
}
