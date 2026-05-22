import QtQuick
import Quickshell
import Quickshell.Io
import qs.core

/**
 * AppLauncherSource - Launcher source for desktop applications
 * Discovers and launches .desktop applications
 * Tracks usage for sorting
 */
QtObject {
    id: root

    readonly property string sourceName: "apps"
    readonly property string displayName: "Applications"
    
    property var items: []
    property bool itemsLoaded: false
    property var _usageData: ({})

    readonly property string usageFilePath: `${Quickshell.shellDir}/app_usage.json`

    // Persistent Process for loading usage data
    property var usageLoader: Process {
        command: ["bash", "-c", "cat " + usageFilePath + " 2>/dev/null || echo {}"]
        running: false
        onRunningChanged: {
            if (!running) {
                var output = stdout;
                if (output) {
                    try {
                        _usageData = JSON.parse(output) || {};
                    } catch (e) {
                        _usageData = {};
                    }
                }
            }
        }
    }

    // Persistent Process for saving usage data
    property var usageSaver: Process {
        command: ["bash", "-c", ""]
        running: false
    }

    // Load usage ONCE at startup
    function refreshItems() {
        itemsLoaded = false;
        loadItems();
    }

    Component.onCompleted: {
        usageLoader.running = true;
        
        // Connect to applicationsChanged only ONCE at startup
        DesktopEntries.applicationsChanged.connect(function() {
            items = [];
            itemsLoaded = false;
        });
    }

    function recordUsage(appItem) {
        if (!appItem || !appItem.name) return;
        
        var key = appItem.name;
        var count = _usageData[key] || 0;
        _usageData[key] = count + 1;
        
        // Save using persistent Process
        usageSaver.command = ["bash", "-c", "echo " + JSON.stringify(JSON.stringify(_usageData)) + " > " + usageFilePath];
        usageSaver.running = true;
    }

    function getUsageCountByItem(appItem) {
        if (!appItem || !appItem.name) return 0;
        return _usageData[appItem.name] || 0;
    }

    function loadItems() {
        if (itemsLoaded) return;

        var rawApps = DesktopEntries.applications.values || [];
        var seenNames = new Set();
        var uniqueApps = [];

        for (var i = 0; i < rawApps.length; i++) {
            var app = rawApps[i];
            var appName = app.name || "";
            if (appName && !seenNames.has(appName)) {
                seenNames.add(appName);
                uniqueApps.push(app);
            }
        }

        items = uniqueApps;
        itemsLoaded = true;
    }

    function filterItems(searchText) {
        loadItems();

        if (!searchText || !searchText.trim()) {
            var sortedItems = items.slice();
            sortedItems.sort(function(a, b) {
                var countA = _usageData[a.name] || 0;
                var countB = _usageData[b.name] || 0;
                if (countA > 0 && countB === 0) return -1;
                if (countB > 0 && countA === 0) return 1;
                return countB - countA;
            });
            return sortedItems;
        }

        var matched = FuzzyMatcher.filterAndSort(items, searchText, function(app) {
            return app.name || "";
        });
        
        matched.sort(function(a, b) {
            var countA = _usageData[a.name] || 0;
            var countB = _usageData[b.name] || 0;
            if (countA > 0 && countB === 0) return -1;
            if (countB > 0 && countA === 0) return 1;
            return countB - countA;
        });
        
        return matched;
    }

    function getItemDisplay(item) {
        var iconPath = item.icon ? Quickshell.iconPath(item.icon, "") : "";
        return {
            icon: iconPath,
            title: item.name || "",
            subtitle: item.comment || ""
        };
    }

    function executeItem(item) {
        if (item && item.execute) {
            recordUsage(item);
            item.execute();
        }
    }

    function getPrefix() {
        return "";
    }
}
