
pragma Singleton
import QtQuick
import Qt.labs.settings

/**
 * NotificationStore - Manages persistent storage of notifications
 */
QtObject {
    id: root

    // Settings object to store notifications
    Settings {
        id: settings
        fileName: "notifications.json"
    }

    // Property to hold the list of notifications
    property var notifications: []

    // Load notifications from storage when component is ready
    Component.onCompleted: {
        loadNotifications()
    }

    // Add a new notification
    function addNotification(notification) {
        notifications.push(notification)
        saveNotifications()
    }

    // Remove a notification by its ID
    function removeNotification(notificationId) {
        notifications = notifications.filter(n => n.id !== notificationId)
        saveNotifications()
    }

    // Load notifications from the JSON file
    function loadNotifications() {
        const storedNotifications = settings.getValue("notifications", [])
        if (storedNotifications) {
            notifications = storedNotifications
        }
    }

    // Save notifications to the JSON file
    function saveNotifications() {
        settings.setValue("notifications", notifications)
    }
}
