pragma ComponentBehavior: Bound

import QtQuick
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

    function _serializeActions(notification) {
        if (!notification?.actions?.length)
            return []

        const out = []
        for (let i = 0; i < notification.actions.length; i++) {
            const action = notification.actions[i]
            if (!action)
                continue
            out.push({
                text: action.text || "",
                identifier: action.identifier || ""
            })
        }
        return out
    }

    function _add(notification) {
        if (!notification || !notification.summary)
            return

        const desktopEntry = notification.desktopEntry || ""
        const id = notification.id || 0
        const actions = _serializeActions(notification)

        console.log(
            "Notification actions:", notification.actions?.length || 0,
            "desktopEntry:", desktopEntry || "(none)"
        )

        if (NotificationModel.count() >= maxNotifications) {
            const oldest = NotificationModel.model.get(NotificationModel.count() - 1)
            if (oldest)
                NotificationService.release(oldest.id)
            NotificationModel.model.remove(NotificationModel.count() - 1)
        }

        try {
            NotificationStore.addNotification({
                summary: notification.summary || "",
                body: notification.body || "",
                appName: notification.appName || "",
                appIcon: notification.appIcon || "",
                image: notification.image || "",
                id: id,
                desktopEntry: desktopEntry,
                actions: actions
            })
        } catch (e) {}

        // Display fields only — actions stay on live Notification via NotificationService
        NotificationModel.add({
            summary: notification.summary || "",
            body: notification.body || "",
            appName: notification.appName || "",
            appIcon: notification.appIcon || "",
            image: notification.image || "",
            id: id,
            desktopEntry: desktopEntry,
            actions: actions,
            timeout: notification.expireTimeout > 0
                ? notification.expireTimeout * 1000
                : Settings.notificationTimeout
        })
    }
}
