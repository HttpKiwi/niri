import QtQuick

/**
 * LauncherSource - Base interface for launcher data sources
 * Implement this to create new launcher backends (apps, clipboard, gifs, etc.)
 */
QtObject {
    id: root

    /** Unique identifier for this source */
    readonly property string sourceName: ""

    /** Human-readable display name */
    readonly property string displayName: ""

    /** All available items from this source (lazy-loaded) */
    property var items: []

    /** Whether items have been loaded */
    property bool itemsLoaded: false

    /**
     * Load all items from the source
     * Called lazily when the launcher opens
     */
    function loadItems() {
        // Override in subclass
    }

    /**
     * Filter and sort items based on search text
     * @param searchText The text to filter by
     * @returns Array of filtered items sorted by relevance
     */
    function filterItems(searchText) {
        // Override in subclass
        return [];
    }

    /**
     * Get display properties for an item
     * @param item The item to get display info for
     * @returns {icon: string, title: string, subtitle: string}
     */
    function getItemDisplay(item) {
        // Override in subclass
        return {icon: "", title: "", subtitle: ""};
    }

    /**
     * Execute an item (e.g., launch app, insert clipboard)
     * @param item The item to execute
     */
    function executeItem(item) {
        // Override in subclass
    }

    /**
     * Get the prefix character for this source (for quick switching)
     * @returns Single character prefix (e.g., ">", ":", "/")
     */
    function getPrefix() {
        return "";
    }
}
