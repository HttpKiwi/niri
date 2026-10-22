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

    // Connections (not .connect()) so the handler dies with this source;
    // DesktopEntries outlives reloads and kept calling into destroyed copies
    property Connections _desktopEntries: Connections {
        target: DesktopEntries
        function onApplicationsChanged() {
            root.items = []
            root.itemsLoaded = false
        }
    }

    function recordUsage(appItem) {
        if (!appItem || !appItem.name)
            return
        Storage.recordAppUsage(appItem.name)
        root.items = root.items.slice().sort(root.byUsage)
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

        items = uniqueApps.sort(root.byUsage)
        itemsLoaded = true
    }

    // Most-used first (counts are >= 0, so unused apps sort last)
    function byUsage(a, b) {
        return Storage.getAppUsageCount(b.name) - Storage.getAppUsageCount(a.name)
    }

    function filterItems(searchText) {
        loadItems()

        // The launcher shows `items` directly for an empty search, so keep it sorted
        if (!searchText || !searchText.trim())
            return items

        var matched = FuzzyMatcher.filterAndSort(items, searchText, function(app) {
            return app.name || ""
        })

        return matched.sort(root.byUsage)
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

}
