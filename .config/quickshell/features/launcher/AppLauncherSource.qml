import QtQuick
import Quickshell
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
    readonly property string searchPlaceholder: "Search applications"

    property var items: []
    property bool itemsLoaded: false

    Component.onCompleted: {
        DesktopEntries.applicationsChanged.connect(function() {
            items = []
            itemsLoaded = false
        })
    }

    function recordUsage(appItem) {
        if (!appItem || !appItem.name)
            return
        Storage.recordAppUsage(appItem.name)
    }

    function refreshItems() {
        itemsLoaded = false
        loadItems()
    }

    function getUsageCountByItem(appItem) {
        if (!appItem || !appItem.name)
            return 0
        return Storage.getAppUsageCount(appItem.name)
    }

    function loadItems() {
        if (itemsLoaded)
            return

        var rawApps = DesktopEntries.applications.values || []
        var seenIds = new Set()
        var uniqueApps = []

        for (var i = 0; i < rawApps.length; i++) {
            var app = rawApps[i]
            if (app.noDisplay)
                continue
            var appId = app.id || ""
            if (!appId || seenIds.has(appId) || Settings.hiddenAppIds.includes(appId))
                continue
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
                var countA = Storage.getAppUsageCount(a.name)
                var countB = Storage.getAppUsageCount(b.name)
                if (countA > 0 && countB === 0)
                    return -1
                if (countB > 0 && countA === 0)
                    return 1
                return countB - countA
            })
            return sortedItems
        }

        var matched = FuzzyMatcher.filterAndSort(items, searchText, function(app) {
            return app.name || ""
        })

        matched.sort(function(a, b) {
            var countA = Storage.getAppUsageCount(a.name)
            var countB = Storage.getAppUsageCount(b.name)
            if (countA > 0 && countB === 0)
                return -1
            if (countB > 0 && countA === 0)
                return 1
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
