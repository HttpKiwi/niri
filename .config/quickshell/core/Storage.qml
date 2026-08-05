pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

/**
 * Storage - JSON-based persistence for shell state
 * Uses FileView for reading and Python heredoc for safe writing
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

    signal notificationsChanged()

    // FileView for reading
    property var fileView: FileView {
        path: root.dataPath
        watchChanges: true

        JsonAdapter {
            id: adapter
            property var notifications
            property var appUsage
        }

        onAdapterUpdated: {
            if (adapter.notifications !== undefined || adapter.appUsage !== undefined) {
                root._data = {
                    notifications: adapter.notifications || [],
                    appUsage: adapter.appUsage || {}
                }
                root.notificationsChanged()
            }
        }

        Component.onCompleted: {
            root._data = {
                notifications: adapter.notifications || [],
                appUsage: adapter.appUsage || {}
            }
            root.notificationsChanged()
        }
    }

    // Reusable Process for saving
    property var saveProcess: Process {
        running: false
    }

    property var legacyUsageMigrator: Process {
        running: false
        command: ["sh", "-c", `test -f '${Quickshell.shellDir}/app_usage.json' && cat '${Quickshell.shellDir}/app_usage.json' || true`]

        stdout: SplitParser {
            onRead: data => {
                const trimmed = data.trim()
                if (!trimmed)
                    return
                try {
                    const legacy = JSON.parse(trimmed)
                    if (legacy && typeof legacy === "object") {
                        const merged = Object.assign({}, root._data.appUsage || {}, legacy)
                        root._data.appUsage = merged
                        root.saveData()
                    }
                } catch (e) {
                    console.warn("Storage: Failed to migrate app_usage.json:", e)
                }
            }
        }
    }

    property Timer usageSaveTimer: Timer {
        interval: 500
        repeat: false
        onTriggered: root.saveData()
    }

    Component.onCompleted: {
        loadData()
        legacyUsageMigrator.running = true
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
        try {
            const jsonStr = JSON.stringify(root._data, null, 2)
            const filePath = root.dataPath
            const dirPath = Quickshell.shellDir
            const tempInputPath = `${filePath}.input.tmp`
            const tempOutputPath = `${filePath}.tmp`

            const writeCommand = `cat > '${tempInputPath}' << 'JSONEOF'
${jsonStr}
JSONEOF
python3 -c "import json, os, shutil; os.makedirs('${dirPath}', exist_ok=True); data = json.load(open('${tempInputPath}')); f = open('${tempOutputPath}', 'w'); json.dump(data, f, indent=2); f.close(); shutil.move('${tempOutputPath}', '${filePath}'); os.remove('${tempInputPath}')"`

            saveProcess.command = ["sh", "-c", writeCommand]
            saveProcess.running = true
            root.notificationsChanged()
        } catch (e) {
            console.error("Storage: Error saving data:", e)
        }
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
            timestamp: notification.timestamp || new Date().toISOString(),
            dismissed: false
        }

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
