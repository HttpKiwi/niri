import QtQuick
import Quickshell.Io
import qs.config
import qs.core

QtObject {
    id: root

    readonly property string sourceName: "clipboard"
    readonly property string displayName: "Clipboard"
    readonly property string searchPlaceholder: "Search clipboard"
    readonly property string thumbDir: Settings.clipboardThumbDir || "/tmp/quickshell-clip-thumbs"

    property var items: []
    property bool itemsLoaded: false
    property bool isLoading: false
    property string statusMessage: ""
    property var _clipboardItems: []
    property var _decodeQueue: []
    property bool _decoding: false
    property string _decodeId: ""
    property string _decodePath: ""
    property bool _previewsDirty: false

    property var previewNotifyTimer: Timer {
        interval: 80
        repeat: false
        onTriggered: {
            if (!root._previewsDirty)
                return
            root._previewsDirty = false
            root._clipboardItems = root._clipboardItems.slice()
            root.items = root._clipboardItems
        }
    }

    function isBinaryPreview(content) {
        const t = (content || "").trim()
        return t.indexOf("[[ binary data") === 0 || t.indexOf("[[binary data") === 0
    }

    function parseBinaryMeta(content) {
        // [[ binary data 66 KiB png 935x970 ]]
        const m = String(content || "").match(
            /\[\[[\s]*binary data[\s]+(\d+(?:\.\d+)?)[\s]*(B|KiB|MiB|GiB)?[\s]+([a-z0-9]+)[\s]+(\d+)x(\d+)[\s]*\]\]/i
        )
        if (!m)
            return { ext: "png", label: "Image", width: 0, height: 0 }

        const size = m[1]
        const unit = m[2] || "B"
        const fmt = (m[3] || "png").toLowerCase()
        const width = Number(m[4]) || 0
        const height = Number(m[5]) || 0
        let ext = "png"
        if (fmt === "jpeg" || fmt === "jpg")
            ext = "jpg"
        else if (fmt === "gif")
            ext = "gif"
        else if (fmt === "webp")
            ext = "webp"
        else if (fmt === "bmp")
            ext = "bmp"
        else if (fmt === "png")
            ext = "png"

        const dim = (width && height) ? (width + "×" + height) : ""
        const label = [dim, size + (unit ? " " + unit : ""), fmt.toUpperCase()]
            .filter(function (s) { return !!s })
            .join(" · ")

        return { ext: ext, label: label || "Image", width: width, height: height }
    }

    function thumbPathFor(id, ext) {
        return thumbDir + "/" + id + "." + ext
    }

    function thumbUrlFor(path) {
        return path ? ("file://" + path) : ""
    }

    property var cliphistProcess: Process {
        id: cliphistProc
        command: ["cliphist", "list"]
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                const output = this.text
                const maxItems = Settings.clipboardMaxItems
                const itemsList = []
                const decodeQueue = []

                if (output) {
                    const lines = output.split("\n")
                    for (let i = 0; i < lines.length && itemsList.length < maxItems; i++) {
                        const line = lines[i]
                        if (!line)
                            continue
                        const tab = line.indexOf("\t")
                        if (tab < 0)
                            continue

                        const id = line.substring(0, tab)
                        const content = line.substring(tab + 1)
                        const binary = root.isBinaryPreview(content)
                        const meta = binary ? root.parseBinaryMeta(content) : null
                        const path = binary ? root.thumbPathFor(id, meta.ext) : ""
                        const item = {
                            id: id,
                            raw: line,
                            content: content,
                            isImage: binary,
                            previewUrl: "",
                            thumbPath: path,
                            subtitle: binary ? meta.label : "",
                            mediaWidth: binary ? meta.width : 0,
                            mediaHeight: binary ? meta.height : 0
                        }
                        itemsList.push(item)
                        if (binary)
                            decodeQueue.push({ id: id, path: path })
                    }
                }

                root._clipboardItems = itemsList
                root.items = itemsList
                root.itemsLoaded = true
                root.isLoading = false
                root.statusMessage = itemsList.length ? "" : "Clipboard empty"
                root._decodeQueue = decodeQueue
                root.pumpDecodeQueue()
            }
        }
    }

    property var decodeProcess: Process {
        id: decodeProc
        running: false
        command: ["true"]

        onExited: function (exitCode, exitStatus) {
            const id = root._decodeId
            const path = root._decodePath
            root._decoding = false
            root._decodeId = ""
            root._decodePath = ""

            if (id && path && exitCode === 0)
                root.applyPreview(id, path)

            root.pumpDecodeQueue()
        }
    }

    property var ensureThumbDir: Process {
        command: ["mkdir", "-p", root.thumbDir]
        running: false
    }

    Component.onCompleted: {
        ensureThumbDir.running = true
        softRefresh()
    }

    function applyPreview(id, path) {
        const url = thumbUrlFor(path)
        let changed = false
        for (let i = 0; i < _clipboardItems.length; i++) {
            if (_clipboardItems[i].id === id) {
                if (_clipboardItems[i].previewUrl !== url) {
                    _clipboardItems[i].previewUrl = url
                    changed = true
                }
                break
            }
        }
        if (changed) {
            _previewsDirty = true
            previewNotifyTimer.restart()
        }
    }

    function pumpDecodeQueue() {
        if (_decoding || !_decodeQueue.length)
            return

        const next = _decodeQueue.shift()
        _decodeQueue = _decodeQueue.slice()
        _decodeId = next.id
        _decodePath = next.path
        _decoding = true

        // Skip re-decode when thumb already exists; otherwise write via cliphist
        decodeProc.command = [
            "sh", "-c",
            "mkdir -p '" + thumbDir + "' && "
                + "if [ -s '" + next.path + "' ]; then exit 0; fi; "
                + "cliphist decode '" + next.id + "' > '" + next.path + "'"
        ]
        decodeProc.running = true
    }

    function softRefresh() {
        if (cliphistProc.running)
            return
        if (!itemsLoaded) {
            isLoading = true
            statusMessage = "Loading…"
        }
        cliphistProc.running = true
    }

    function refreshItems() {
        softRefresh()
    }

    function loadItems() {
        if (itemsLoaded || isLoading)
            return
        softRefresh()
    }

    function filterItems(searchText) {
        loadItems()

        if (!searchText || !searchText.trim())
            return _clipboardItems

        const query = searchText.trim().toLowerCase()
        const matched = []
        for (let i = 0; i < _clipboardItems.length; i++) {
            const item = _clipboardItems[i]
            const hay = ((item.content || "") + " " + (item.subtitle || "")).toLowerCase()
            if (hay.indexOf(query) !== -1)
                matched.push(item)
        }
        return matched
    }

    function getItemDisplay(item) {
        if (item.isImage) {
            return {
                icon: item.previewUrl || "",
                title: item.previewUrl ? "Image" : "Image…",
                subtitle: item.subtitle || "Image"
            }
        }

        const text = item.content || ""
        const truncated = text.length > 100 ? text.substring(0, 100) + "..." : text
        return {
            icon: "",
            title: truncated,
            subtitle: ""
        }
    }

    property var copyProcess: Process {
        command: ["sh", "-c", ""]
        running: false
    }

    function executeItem(item) {
        if (!item || !item.id)
            return

        // Prefer cached thumb for images (faster, correct MIME via file bytes)
        if (item.isImage && item.thumbPath) {
            const ext = item.thumbPath.split(".").pop()
            let mime = "image/png"
            if (ext === "jpg" || ext === "jpeg")
                mime = "image/jpeg"
            else if (ext === "gif")
                mime = "image/gif"
            else if (ext === "webp")
                mime = "image/webp"
            copyProcess.command = [
                "sh", "-c",
                "if [ -s '" + item.thumbPath + "' ]; then "
                    + "wl-copy --type " + mime + " < '" + item.thumbPath + "'; "
                    + "else cliphist decode '" + item.id + "' | wl-copy; fi"
            ]
        } else {
            copyProcess.command = ["sh", "-c", "cliphist decode '" + item.id + "' | wl-copy"]
        }
        copyProcess.running = true
    }

    function getPrefix() {
        return ":"
    }
}
