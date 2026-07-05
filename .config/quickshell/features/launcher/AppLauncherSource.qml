import QtQuick
import Quickshell
import Quickshell.Io
import qs.core
import qs.config

/**
 * AppLauncherSource - Launcher source for desktop applications
 * Discovers and launches .desktop applications
 * Tracks usage for sorting with persistent storage
 */
QtObject {
    id: root

    readonly property string sourceName: "apps"
    readonly property string displayName: "Applications"
    
    property var items: []
    property bool itemsLoaded: false
    property var _usageData: ({})
    property var _saveTimer: null

    readonly property string usageFilePath: `${Quickshell.shellDir}/app_usage.json`

    // FileView for reading usage data
    property var usageFileView: FileView {
        path: usageFilePath
        watchChanges: false

        JsonAdapter {
            id: usageAdapter
        }

        onAdapterUpdated: {
            if (usageAdapter) {
                try {
                    const raw = JSON.parse(JSON.stringify(usageAdapter))
                    root._usageData = raw || {}
                } catch (e) {
                    root._usageData = {}
                }
            }
        }

        Component.onCompleted: {
            if (usageAdapter) {
                try {
                    const raw = JSON.parse(JSON.stringify(usageAdapter))
                    root._usageData = raw || {}
                } catch (e) {
                    root._usageData = {}
                }
            }
        }
    }

    // Reusable Process for saving usage data
    property var usageSaver: Process {
        command: ["sh", "-c", ""]
        running: false
    }

    Component.onCompleted: {
        usageFileView.reload()
        
        DesktopEntries.applicationsChanged.connect(function() {
            items = []
            itemsLoaded = false
        })
    }

    function recordUsage(appItem) {
        if (!appItem || !appItem.name) return
        
        var key = appItem.name
        var count = _usageData[key] || 0
        _usageData[key] = count + 1
        
        _scheduleSave()
    }

    function _scheduleSave() {
        if (_saveTimer) {
            _saveTimer.restart()
        } else {
            _saveTimer = Qt.createQmlObject(`
                import QtQuick;
                Timer {
                    interval: 500
                    repeat: false
                    onTriggered: {
                        root._flushSave()
                    }
                }
            `, root)
            _saveTimer.start()
        }
    }

    function _flushSave() {
        try {
            const jsonStr = JSON.stringify(_usageData)
            const escapedJson = jsonStr.replace(/'/g, "'\\''")
            usageSaver.command = ["sh", "-c", `printf '%s' '${escapedJson}' > '${usageFilePath}'`]
            usageSaver.running = true
        } catch (e) {
            console.error("AppLauncherSource: Failed to save usage data:", e)
        }
    }

    function refreshItems() {
        itemsLoaded = false
        loadItems()
    }

    function getUsageCountByItem(appItem) {
        if (!appItem || !appItem.name) return 0
        return _usageData[appItem.name] || 0
    }

    function loadItems() {
        if (itemsLoaded) return

        var rawApps = DesktopEntries.applications.values || []
        var seenIds = new Set()
        var uniqueApps = []

        for (var i = 0; i < rawApps.length; i++) {
            var app = rawApps[i]
            if (app.noDisplay) continue
            var appId = app.id || ""
            if (!appId || seenIds.has(appId) || Settings.hiddenAppIds.includes(appId)) continue
            seenIds.add(appId)
            uniqueApps.push(app)
        }

        items = uniqueApps
        itemsLoaded = true


    }

    function filterItems(searchText) {
        loadItems()

        if (!searchText || !searchText.trim()) {
            var sortedItems = items.slice()
            sortedItems.sort(function(a, b) {
                var countA = _usageData[a.name] || 0
                var countB = _usageData[b.name] || 0
                if (countA > 0 && countB === 0) return -1
                if (countB > 0 && countA === 0) return 1
                return countB - countA
            })
            return sortedItems
        }

        var matched = FuzzyMatcher.filterAndSort(items, searchText, function(app) {
            return app.name || ""
        })
        
        matched.sort(function(a, b) {
            var countA = _usageData[a.name] || 0
            var countB = _usageData[b.name] || 0
            if (countA > 0 && countB === 0) return -1
            if (countB > 0 && countA === 0) return 1
            return countB - countA
        })
        
        return matched
    }

    function getItemDisplay(item) {
        var iconPath = item.icon ? Quickshell.iconPath(item.icon, "") : ""
        return {
            icon: iconPath,
            title: item.name || "",
            subtitle: item.comment || ""
        }
    }

    function executeItem(item) {
        if (item && item.execute) {
            recordUsage(item)
            item.execute()
        }
    }

    function getPrefix() {
        return ""
    }
}
