import QtQuick
import Quickshell.Io
import qs.core
import qs.config

/**
 * GifLauncherSource - Online GIF search via KLIPY API v1
 * Set KLIPY_API_KEY in ~/.config/quickshell/secrets.env
 */
QtObject {
    id: root

    readonly property string sourceName: "gifs"
    readonly property string displayName: "GIFs"
    readonly property string searchPlaceholder: "Search GIFs"

    property var items: []
    property bool itemsLoaded: false
    property bool isLoading: false
    property string statusMessage: ""
    property string _lastQuery: ""
    property string _pendingQuery: ""

    signal itemsUpdated()

    property var searchTimer: Timer {
        interval: Settings.launcherSearchDebounceMs
        onTriggered: root.fetchForQuery(root._pendingQuery)
    }

    property var copyProcess: Process {
        running: false
    }

    property string _klipyKey: Settings.klipyApiKey
    property bool _klipyReady: Settings.klipyReady

    on_KlipyReadyChanged: {
        if (_klipyReady)
            retryPendingSearch()
    }

    on_KlipyKeyChanged: {
        if (_klipyKey)
            retryPendingSearch()
    }

    Component.onCompleted: {
        Settings.secretsLoaded.connect(retryPendingSearch)
    }

    function retryPendingSearch() {
        if (!Settings.klipyReady)
            return
        if (!Settings.klipyApiKey) {
            items = []
            statusMessage = "Set KLIPY_API_KEY in ~/.config/quickshell/secrets.env"
            itemsLoaded = true
            isLoading = false
            itemsUpdated()
            return
        }
        if (isLoading || !itemsLoaded || statusMessage.indexOf("KLIPY_API_KEY") !== -1)
            scheduleSearch(_pendingQuery)
    }

    function shellQuote(value) {
        return "'" + String(value).replace(/'/g, "'\\''") + "'"
    }

    function refreshItems() {
        itemsLoaded = false
        loadItems()
    }

    function loadItems() {
        if (itemsLoaded || isLoading)
            return
        scheduleSearch("")
    }

    function filterItems(searchText) {
        var query = (searchText || "").trim()
        if (query === _lastQuery && itemsLoaded)
            return items
        scheduleSearch(query)
        return items
    }

    function scheduleSearch(query) {
        _pendingQuery = query

        if (!Settings.klipyReady) {
            isLoading = true
            statusMessage = "Loading…"
            itemsUpdated()
            return
        }

        if (!Settings.klipyApiKey) {
            items = []
            statusMessage = "Set KLIPY_API_KEY in ~/.config/quickshell/secrets.env"
            itemsLoaded = true
            isLoading = false
            itemsUpdated()
            return
        }

        if (isLoading && query === _lastQuery)
            return

        isLoading = true
        statusMessage = query ? "Searching GIFs…" : "Loading GIFs…"
        searchTimer.restart()
    }

    function buildRequestUrl(endpoint, query) {
        var base = Settings.klipyApiBase + "/"
            + encodeURIComponent(Settings.klipyApiKey)
            + "/gifs/" + endpoint
        var params = [
            "per_page=" + Settings.klipySearchLimit,
            "locale=" + encodeURIComponent(Settings.klipyLocale)
        ]

        if (query)
            params.push("q=" + encodeURIComponent(query))

        return base + "?" + params.join("&")
    }

    function pickMedia(fileTree, preferThumb, sizeOrder) {
        if (!fileTree)
            return null

        var order = sizeOrder
        if (!order)
            order = preferThumb ? ["sm", "md", "xs", "hd"] : ["md", "hd", "sm", "xs"]
        for (var i = 0; i < order.length; i++) {
            var bucket = fileTree[order[i]]
            if (!bucket)
                continue

            if (preferThumb && bucket.jpg && bucket.jpg.url)
                return bucket.jpg
            if (bucket.gif && bucket.gif.url)
                return bucket.gif
            if (bucket.webp && bucket.webp.url)
                return bucket.webp
        }
        return null
    }

    function fetchForQuery(query) {
        if (!Settings.klipyReady || !Settings.klipyApiKey)
            return

        _lastQuery = query
        isLoading = true
        statusMessage = query ? "Searching GIFs…" : "Loading GIFs…"
        itemsUpdated()

        var endpoint = query ? "search" : "trending"
        var url = buildRequestUrl(endpoint, query)

        HttpClient.get(url, function(err, body) {
            isLoading = false

            if (err) {
                items = []
                statusMessage = "GIF search failed"
                console.warn("GifLauncher:", err)
                itemsLoaded = true
                itemsUpdated()
                return
            }

            try {
                var data = JSON.parse(body)
                var rows = (data && data.data && data.data.data) ? data.data.data : []
                items = parseResults(rows)
                statusMessage = items.length ? "" : "No GIFs found"
                itemsLoaded = true
                itemsUpdated()
            } catch (e) {
                items = []
                statusMessage = "Invalid GIF response"
                console.warn("GifLauncher: parse error", e)
                itemsLoaded = true
                itemsUpdated()
            }
        })
    }

    function parseResults(results) {
        var out = []
        for (var i = 0; i < results.length; i++) {
            var entry = results[i]
            var gif = pickMedia(entry.file, false)
            var thumb = pickMedia(entry.file, true)
            var preview = pickMedia(entry.file, false, ["sm", "md", "xs", "hd"])
            if (!gif || !gif.url)
                continue

            out.push({
                id: String(entry.id),
                slug: entry.slug || "",
                title: entry.title || "GIF",
                url: gif.url,
                embedUrl: entry.slug ? ("https://klipy.com/gifs/" + entry.slug) : gif.url,
                previewUrl: (preview && preview.url) || gif.url,
                thumbUrl: (thumb && thumb.url) || gif.url,
                width: gif.width || 0,
                height: gif.height || 0,
                searchTerm: _lastQuery
            })
        }
        return out
    }

    function getItemDisplay(item) {
        var dims = item.width && item.height ? item.width + "×" + item.height : ""
        return {
            icon: item.thumbUrl || "",
            title: item.title || "GIF",
            subtitle: dims
        }
    }

    function registerShare(item) {
        if (!item || !item.id || !Settings.klipyApiKey)
            return

        var params = [
            "key=" + encodeURIComponent(Settings.klipyApiKey),
            "client_key=quickshell",
            "id=" + encodeURIComponent(item.id)
        ]
        if (item.searchTerm)
            params.push("q=" + encodeURIComponent(item.searchTerm))

        HttpClient.get("https://api.klipy.com/v2/registershare?" + params.join("&"))
    }

    function executeItem(item) {
        if (!item)
            return

        registerShare(item)

        // Discord inlines pasted .gif URLs; Klipy page links may not unfurl yet
        var link = item.url || item.embedUrl
        if (!link)
            return

        copyProcess.command = ["wl-copy", link]
        copyProcess.running = true
    }

    function getPrefix() {
        return ";"
    }
}
