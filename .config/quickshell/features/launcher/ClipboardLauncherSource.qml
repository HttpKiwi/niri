import QtQuick
import Quickshell.Io
import qs.core

QtObject {
    id: root

    readonly property string sourceName: "clipboard"
    readonly property string displayName: "Clipboard"
    readonly property string searchPlaceholder: "Search clipboard"

    property var items: []
    property bool itemsLoaded: false
    property var _clipboardItems: []
    property bool _isLoading: false

    property var cliphistProcess: Process {
        id: cliphistProc
        command: ["sh", "-c", "cliphist list"]
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                _isLoading = false;
                var output = this.text;
                if (!output) {
                    itemsLoaded = true;
                    return;
                }
                
                var itemsList = [];
                var regex = /(\d+)\t([^\n]*)/g;
                var match;
                
                while ((match = regex.exec(output)) !== null) {
                    itemsList.push({
                        id: match[1],
                        content: match[2]
                    });
                }
                
                _clipboardItems = itemsList;
                items = itemsList;
                itemsLoaded = true;
            }
        }
    }

    Component.onCompleted: {
        cliphistProc.running = true;
        cliphistProc.running = false;
    }

    function refreshItems() {
        _isLoading = true;
        itemsLoaded = false;
        cliphistProc.running = true;
    }

    function loadItems() {
        if (itemsLoaded || _isLoading) return;
        cliphistProc.running = true;
    }

    function filterItems(searchText) {
        loadItems();

        if (!searchText || !searchText.trim()) {
            return _clipboardItems;
        }

        return FuzzyMatcher.filterAndSort(_clipboardItems, searchText, function(item) {
            return item.content || "";
        });
    }

    function getItemDisplay(item) {
        var text = item.content || "";
        var truncated = text.length > 100 ? text.substring(0, 100) + "..." : text;
        var isImage = text.startsWith("Image: ");
        
        return {
            icon: "",
            title: truncated,
            subtitle: isImage ? "Image" : ""
        };
    }

    property var copyProcess: Process {
        command: ["sh", "-c", ""]
        running: false
    }

    function executeItem(item) {
        if (!item || !item.id) return;

        copyProcess.command = ["sh", "-c", "cliphist decode " + item.id + " | wl-copy"];
        copyProcess.running = true;
    }

    function getPrefix() {
        return ":";
    }
}
