pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.core
import qs.config

QtObject {
    id: manager

    property int maxNotifications: Settings.notificationMaxStack

    property Connections notificationConnections: Connections {
        target: NotificationService
        function onNotificationReceived(notification) {
            manager._add(notification)
        }
    }

    function _add(notification) {
        if (!notification || !notification.summary) return

        if (NotificationModel.count() >= maxNotifications) {
            NotificationModel.model.remove(NotificationModel.count() - 1)
        }

        try {
            NotificationStore.addNotification({
                summary: notification.summary || "",
                body: notification.body || "",
                appName: notification.appName || "",
                appIcon: notification.appIcon || "",
                image: notification.image || "",
                id: notification.id || 0
            })
        } catch (e) {}

        NotificationModel.add({
            summary: notification.summary || "",
            body: notification.body || "",
            appName: notification.appName || "",
            appIcon: notification.appIcon || "",
            image: notification.image || "",
            id: notification.id || 0,
            timeout: notification.expireTimeout || Settings.notificationTimeout
        })
    }

    function _getWrapper() {
        const name = Niri.focused_output_name;
        return name ? PopupRegistry.notifWrappers[name] : null;
    }
}
