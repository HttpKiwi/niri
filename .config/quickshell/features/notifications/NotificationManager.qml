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

    property var _recentFingerprints: []

    function _fingerprint(notification) {
        const entry = (notification.desktopEntry || notification.appName || "").toString().toLowerCase()
        const summary = (notification.summary || "").toString().trim()
        const body = (notification.body || "").toString().trim()
        return `${entry}\n${summary}\n${body}`
    }

    function _isDuplicate(notification) {
        const now = Date.now()
        const fp = _fingerprint(notification)
        const windowMs = 2500
        manager._recentFingerprints = manager._recentFingerprints.filter(r => now - r.at < windowMs)
        if (manager._recentFingerprints.some(r => r.fp === fp))
            return true
        manager._recentFingerprints.push({ fp: fp, at: now })
        return false
    }

    function _add(notification) {
        if (!notification || !notification.summary)
            return

        // KDE Connect (and some apps) emit the same Notify twice, or a replace as a new popup
        if (manager._isDuplicate(notification)) {
            console.log("Notification skipped duplicate:", notification.summary)
            return
        }

        const desktopEntry = notification.desktopEntry || ""
        const id = notification.id || 0
        const actions = _serializeActions(notification)

        console.log(
            "Notification actions:", notification.actions?.length || 0,
            "desktopEntry:", desktopEntry || "(none)"
        )

        if (NotificationModel.count() >= maxNotifications) {
            // Model appends, so index 0 is the oldest popup
            const oldest = NotificationModel.model.get(0)
            if (oldest)
                NotificationService.release(oldest.id)
            NotificationModel.model.remove(0)
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
                actions: actions,
                urgency: notification.urgency
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
