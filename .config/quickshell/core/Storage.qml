pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

/**
 * Storage - JSON-based persistence for shell state
 * FileView reads and writes (atomic) shell_data.json
 *
 * Data structure:
 * {
 *   "notifications": [{id, appName, summary, body, appIcon, image, desktopEntry, timestamp, dismissed}],
 *   "appUsage": {appName: count}
 * }
 * Shell prefs live in Settings.qml → common/shell-prefs.json (not here).
 */
QtObject {
    id: root

    readonly property string dataPath: `${Quickshell.shellDir}/shell_data.json`

    // Internal storage
    property var _data: ({ notifications: [], appUsage: {} })
    // Never write before the file has been read: on reload, re-delivered
    // notifications call saveData() immediately and would clobber history
    property bool _loaded: false

    signal notificationsChanged()

    // Parse text ourselves: JsonAdapter `var` props don't round-trip the
    // appUsage object (it came back as {} and usage counts were lost)
    property var fileView: FileView {
        path: root.dataPath
        // Read synchronously so _data is populated before any caller can save
        blockLoading: true

        onLoaded: {
            try {
                const obj = JSON.parse(text() || "{}")
                root._data = {
                    notifications: Array.isArray(obj.notifications) ? obj.notifications : [],
                    appUsage: (obj.appUsage && typeof obj.appUsage === "object") ? obj.appUsage : {}
                }
            } catch (e) {
                // Corrupt file: keep it on disk, refuse to overwrite
                console.error("Storage: cannot parse", root.dataPath, e)
                return
            }
            root._loaded = true
            root.notificationsChanged()
        }
        onLoadFailed: err => {
            // Missing file is a fresh start; anything else must not be overwritten
            if (err === FileViewError.FileNotFound)
                root._loaded = true
            else
                console.error("Storage: cannot read", root.dataPath, FileViewError.toString(err))
        }
    }

    property Timer usageSaveTimer: Timer {
        interval: 500
        repeat: false
        onTriggered: root.saveData()
    }

    Component.onCompleted: {
        loadData()
    }

    function loadData() {
        try {
            fileView.reload()
        } catch (e) {
            console.warn("Storage: Error loading data:", e)
            root._data = { notifications: [], appUsage: {} }
        }
    }

    function saveData() {
        if (!root._loaded) {
            console.warn("Storage: save skipped, data not loaded yet")
            return
        }
        fileView.setText(JSON.stringify(root._data, null, 2))
        root.notificationsChanged()
    }

    // Notification operations
    function addNotification(notification) {
        if (!notification || !notification.appName) return

        const notificationData = {
            id: String(notification.id || Date.now()),
            appName: notification.appName || "Unknown",
            summary: notification.summary || "",
            body: notification.body || "",
            appIcon: notification.appIcon || "",
            image: notification.image || "",
            desktopEntry: notification.desktopEntry || "",
            actions: notification.actions || [],
            urgency: notification.urgency ?? 1,
            timestamp: notification.timestamp || new Date().toISOString(),
            dismissed: false
        }

        const existing = root._data.notifications.findIndex(n => String(n.id) === notificationData.id)
        if (existing >= 0)
            root._data.notifications.splice(existing, 1)
        root._data.notifications.unshift(notificationData)
        trimOldNotifications()
        saveData()
    }

    function dismissNotification(notificationId) {
        const id = String(notificationId)
        for (var i = 0; i < root._data.notifications.length; i++) {
            if (root._data.notifications[i].id === id) {
                root._data.notifications[i].dismissed = true
                break
            }
        }
        saveData()
    }

    function removeNotification(notificationId) {
        const id = String(notificationId)
        root._data.notifications = root._data.notifications.filter(function(n) {
            return n.id !== id
        })
        saveData()
    }

    function getActiveNotifications(callback) {
        var active = root._data.notifications.filter(function(n) {
            return !n.dismissed
        })
        callback(active)
    }

    function getAllNotifications(callback) {
        callback(root._data.notifications.slice())
    }

    function getGroupedNotifications(callback) {
        var groups = {}
        for (var i = 0; i < root._data.notifications.length; i++) {
            var n = root._data.notifications[i]
            if (!n.dismissed) {
                if (!groups[n.appName]) {
                    groups[n.appName] = {
                        appName: n.appName,
                        notifications: [],
                        count: 0
                    }
                }
                groups[n.appName].notifications.push(n)
                groups[n.appName].count++
            }
        }
        var result = []
        for (var key in groups) {
            result.push(groups[key])
        }
        callback(result)
    }

    function getNotificationsByApp(appName, callback) {
        var result = root._data.notifications.filter(function(n) {
            return n.appName === appName
        })
        callback(result)
    }

    function clearApp(appName) {
        root._data.notifications = root._data.notifications.filter(function(n) {
            return n.appName !== appName
        })
        saveData()
    }

    function clearAll() {
        root._data.notifications = []
        saveData()
    }

    function trimOldNotifications() {
        var maxAgeDays = Settings.notificationHistoryMaxAgeDays || 0
        var maxPerApp = Settings.notificationHistoryMaxPerApp || 100
        var maxTotal = Settings.notificationHistoryMaxTotal || 1000

        var now = new Date()

        // Age-based trim
        if (maxAgeDays > 0) {
            var maxAgeMs = maxAgeDays * 24 * 60 * 60 * 1000
            root._data.notifications = root._data.notifications.filter(function(n) {
                if (!n.timestamp) return true
                try {
                    var notificationDate = new Date(n.timestamp)
                    return (now - notificationDate) <= maxAgeMs
                } catch (e) {
                    return true
                }
            })
        }

        // Per-app limit
        var appCounts = {}
        for (var i = root._data.notifications.length - 1; i >= 0; i--) {
            var n = root._data.notifications[i]
            var appName = n.appName || "Unknown"
            if (!appCounts[appName]) appCounts[appName] = 0
            appCounts[appName]++
            if (appCounts[appName] > maxPerApp) {
                root._data.notifications.splice(i, 1)
            }
        }

        // Total limit
        if (root._data.notifications.length > maxTotal) {
            root._data.notifications = root._data.notifications.slice(0, maxTotal)
        }
    }

    // App launcher usage (merged from legacy app_usage.json)
    function getAppUsageCount(appName) {
        if (!appName || !root._data.appUsage)
            return 0
        return root._data.appUsage[appName] || 0
    }

    function recordAppUsage(appName) {
        if (!appName)
            return
        if (!root._data.appUsage)
            root._data.appUsage = {}
        root._data.appUsage[appName] = (root._data.appUsage[appName] || 0) + 1
        usageSaveTimer.restart()
    }
}
