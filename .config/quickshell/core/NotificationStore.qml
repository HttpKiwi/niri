pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import QtQuick
import qs.config

/**
 * NotificationStore - Manages persistent storage of notification history
 * Stores notifications grouped by application in a JSON file
 */
QtObject {
    id: root

    // Internal storage structure: { "apps": { "AppName": [notifications...] } }
    property var _storage: ({ apps: {} })
    
    readonly property string storagePath: `${Quickshell.shellDir}/notification_history.json`
    
    // Process object reference for cleanup
    property var _saveProcess: null
    
    // Signal emitted when notifications are updated
    signal notificationsChanged()

    Component.onCompleted: {
        loadNotifications()
    }
    
    Component.onDestruction: {
        // Clean up process object
        if (_saveProcess) {
            try {
                _saveProcess.destroy()
            } catch (e) {
                // Ignore cleanup errors
            }
            _saveProcess = null
        }
    }

    // FileView for reading JSON file
    property FileView fileView: FileView {
        id: fileView
        path: storagePath
        watchChanges: false
        
        JsonAdapter {
            id: adapter
            property var apps
            
            onAppsChanged: {
                if (apps) {
                    root._storage = { apps: apps }
                    root.notificationsChanged()
                }
            }
        }
        
        Component.onCompleted: {
            if (adapter && adapter.apps) {
                root._storage = { apps: adapter.apps }
            } else {
                root._storage = { apps: {} }
            }
        }
    }

    // Load notifications from JSON file
    function loadNotifications() {
        try {
            fileView.reload()
            if (fileView.adapter && fileView.adapter.apps) {
                _storage = { apps: fileView.adapter.apps }
                // Trim old notifications on load to ensure limits are enforced
                trimOldNotifications()
                // Save trimmed data if trimming occurred
                saveNotifications()
            } else {
                _storage = { apps: {} }
            }
            notificationsChanged()
        } catch (e) {
            console.warn("Error loading notification history:", e)
            _storage = { apps: {} }
        }
    }

    // Save notifications to JSON file
    function saveNotifications() {
        try {
            // Clean up previous process if it exists
            if (_saveProcess) {
                try {
                    _saveProcess.destroy()
                } catch (e) {
                    // Ignore cleanup errors
                }
                _saveProcess = null
            }
            
            const jsonStr = JSON.stringify(_storage, null, 2)
            const filePath = storagePath
            const dirPath = Quickshell.shellDir
            const tempInputPath = `${filePath}.input.tmp`
            const tempOutputPath = `${filePath}.tmp`
            
            // Escape the JSON string for shell: escape single quotes and wrap in single quotes
            const escapedJson = jsonStr.replace(/'/g, "'\"'\"'")
            
            // Write JSON to temp file using here-document, then Python formats and moves it
            // This safely handles all special characters
            const writeCommand = `cat > '${tempInputPath}' << 'JSONEOF'
${jsonStr}
JSONEOF
python3 -c "import json, os, shutil; os.makedirs('${dirPath}', exist_ok=True); data = json.load(open('${tempInputPath}')); f = open('${tempOutputPath}', 'w'); json.dump(data, f, indent=2); f.close(); shutil.move('${tempOutputPath}', '${filePath}'); os.remove('${tempInputPath}')"`
            
            _saveProcess = Qt.createQmlObject(`
                import Quickshell.Io;
                Process {
                    id: proc
                    command: ["sh", "-c", ${JSON.stringify(writeCommand)}]
                    running: true
                    onFinished: {
                        proc.destroy()
                    }
                }
            `, root)
            
            notificationsChanged()
        } catch (e) {
            console.error("Error saving notification history:", e)
        }
    }

    // Trim old notifications to enforce limits
    function trimOldNotifications() {
        const maxPerApp = Settings.notificationHistoryMaxPerApp || 100
        const maxTotal = Settings.notificationHistoryMaxTotal || 1000
        const maxAgeDays = Settings.notificationHistoryMaxAgeDays || 0
        
        let totalCount = 0
        const now = new Date()
        
        // First pass: trim by age if enabled
        if (maxAgeDays > 0) {
            const maxAgeMs = maxAgeDays * 24 * 60 * 60 * 1000
            for (const appName in _storage.apps) {
                if (_storage.apps[appName]) {
                    _storage.apps[appName] = _storage.apps[appName].filter(n => {
                        if (!n.timestamp) return true
                        try {
                            const notificationDate = new Date(n.timestamp)
                            const ageMs = now - notificationDate
                            return ageMs <= maxAgeMs
                        } catch (e) {
                            return true
                        }
                    })
                }
            }
        }
        
        // Second pass: trim per-app limits
        for (const appName in _storage.apps) {
            if (_storage.apps[appName] && _storage.apps[appName].length > maxPerApp) {
                _storage.apps[appName] = _storage.apps[appName].slice(0, maxPerApp)
            }
            totalCount += _storage.apps[appName] ? _storage.apps[appName].length : 0
        }
        
        // Third pass: trim total limit (remove oldest across all apps)
        if (totalCount > maxTotal) {
            const allNotifications = []
            for (const appName in _storage.apps) {
                if (_storage.apps[appName]) {
                    for (const n of _storage.apps[appName]) {
                        allNotifications.push({
                            appName: appName,
                            notification: n,
                            timestamp: n.timestamp || ""
                        })
                    }
                }
            }
            
            // Sort by timestamp (oldest first)
            allNotifications.sort((a, b) => {
                if (!a.timestamp) return 1
                if (!b.timestamp) return -1
                return a.timestamp.localeCompare(b.timestamp)
            })
            
            // Keep only the newest maxTotal notifications
            const toKeep = allNotifications.slice(-maxTotal)
            
            // Rebuild storage
            _storage.apps = {}
            for (const item of toKeep) {
                if (!_storage.apps[item.appName]) {
                    _storage.apps[item.appName] = []
                }
                _storage.apps[item.appName].push(item.notification)
            }
        }
    }

    // Add a notification to the store
    function addNotification(notification) {
        if (!notification || !notification.appName) {
            return
        }
        
        const appName = notification.appName || "Unknown"
        const timestamp = new Date().toISOString()
        
        const notificationData = {
            id: notification.id || Date.now(),
            summary: notification.summary || "",
            body: notification.body || "",
            appIcon: notification.appIcon || "",
            image: notification.image || "",
            timestamp: timestamp,
            dismissed: false
        }
        
        // Initialize app group if it doesn't exist
        if (!_storage.apps[appName]) {
            _storage.apps[appName] = []
        }
        
        // Add notification to the app's list
        _storage.apps[appName].unshift(notificationData) // Add to beginning
        
        // Trim old notifications before saving
        trimOldNotifications()
        
        saveNotifications()
    }

    // Remove a notification by ID from an app
    function removeNotification(appName, notificationId) {
        if (!_storage.apps[appName]) {
            return
        }
        
        _storage.apps[appName] = _storage.apps[appName].filter(n => n.id !== notificationId)
        
        // Remove app group if empty
        if (_storage.apps[appName].length === 0) {
            delete _storage.apps[appName]
        }
        
        saveNotifications()
    }

    // Get all notifications for a specific app
    function getNotificationsByApp(appName) {
        if (!_storage.apps[appName]) {
            return []
        }
        return _storage.apps[appName] || []
    }

    // Get all app names that have notifications
    function getAppNames() {
        return Object.keys(_storage.apps || {})
    }

    // Get all notifications grouped by app (for UI)
    function getGroupedNotifications() {
        const groups = []
        const appNames = getAppNames()
        
        for (const appName of appNames) {
            groups.push({
                appName: appName,
                notifications: _storage.apps[appName],
                count: _storage.apps[appName].length
            })
        }
        
        return groups
    }

    // Clear all notifications
    function clearAll() {
        _storage = { apps: {} }
        saveNotifications()
    }

    // Clear notifications for a specific app
    function clearApp(appName) {
        if (_storage.apps[appName]) {
            delete _storage.apps[appName]
            saveNotifications()
        }
    }
}

