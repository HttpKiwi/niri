pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import Quickshell
import qs.config
import qs.services

/**
 * Menu - the island grown into a pebble: one palette for apps, windows,
 * maths and units, tools, the phone, clipboard, notifications and the
 * system. Keyboard first: type, ↑↓, Enter, Tab between sections, Esc.
 */
Item {
    id: root

    required property bool open
    required property string output

    readonly property var sections: [
        { id: "apps", label: "Apps" },
        { id: "windows", label: "Windows" }, { id: "tools", label: "Tools" },
        { id: "phone", label: "Phone" }, { id: "clipboard", label: "Clipboard" },
        { id: "wallpapers", label: "Wallpapers" },
        { id: "inbox", label: "Inbox" }, { id: "system", label: "System" }
    ]
    // Tab walks the sections and back to "all" (no tab lit): sections are filters on a search of everything
    function cycle(dir) {
        const idx = sections.findIndex(s => s.id === Ui.section);
        const next = idx + dir;
        Ui.section = next < 0 || next >= sections.length ? (idx === -1 && dir < 0 ? sections[sections.length - 1].id : "all") : sections[next].id;
    }
    property string query: ""
    property int sel: 0
    property string confirmKey: ""     // a dangerous item waiting for a second Enter
    property bool showQr: false

    onOpenChanged: {
        if (!open) { previewTimer.stop(); Wallpaper.revert(); return; }
        input.text = "";
        resetSel();
        expanded = ({});
        confirmKey = "";
        showQr = false;
        if (Ui.section === "clipboard") Tools.loadClips();
        if (Ui.section === "phone" || Ui.section === "all") Tools.loadPhoneApps();
        if (Ui.section === "wallpapers") Wallpaper.load();
        if (Ui.section === "inbox") Notifs.markRead();
        focusTimer.restart();
    }
    Timer { id: focusTimer; interval: 60; onTriggered: input.forceActiveFocus() }
    ParallelAnimation {
        id: swap
        NumberAnimation { target: list; property: "opacity"; from: 0; to: 1; duration: 260; easing.type: Easing.OutCubic }
        NumberAnimation { target: listShift; property: "y"; from: 10; to: 0; duration: 360; easing.type: Easing.OutBack; easing.overshoot: 1.3 }
    }
    Connections {
        target: Ui
        function onSectionChanged() {
            swap.restart();
            root.resetSel();
            root.expanded = ({});
            root.confirmKey = "";
            if (Ui.section === "clipboard") Tools.loadClips();
            if (Ui.section === "phone") Tools.loadPhoneApps();
            if (Ui.section === "wallpapers") Wallpaper.load(); else Wallpaper.revert();
            if (Ui.section === "inbox") Notifs.markRead();
        }
    }
    Connections {
        target: Tools
        function onQrReady() { root.showQr = true; }
    }

    // ---- matching ----
    // Tight on purpose: the query has to START the title or one of its words
    // ("code" → Visual Studio Code), match its initials ("gc" → Google Chrome), or
    // (3+ letters) sit inside it. Letters scattered across a title no longer count.
    function score(text, q) {
        if (!q) return 1;
        const t = (text ?? "").toLowerCase();
        if (!t) return 0;
        if (t.startsWith(q)) return 100 - Math.min(t.length, 40) * 0.1;
        const ws = t.split(/[^a-z0-9]+/).filter(w => w);
        if (ws.some(w => w.startsWith(q))) return 70;
        if (q.length >= 2 && ws.map(w => w[0]).join("").startsWith(q)) return 60;
        if (q.length >= 3 && t.includes(q)) return 40;
        return 0;
    }
    function ranked(items, q) {
        if (!q) return items;
        return items.map((it, i) => {
            const ids = it.ids ?? [];
            const base = Math.max(
                ids.some(x => x === q) ? 98 : 0,            // typed the command: "code", "zen"
                ids.some(x => x.startsWith(q)) ? 75 : 0,
                score(it.title, q),
                score(it.keys ?? "", q) >= 70 ? 55 : 0,     // keywords / id: word starts only
                score(it.sub, q) >= 70 ? 28 : 0);           // description: word starts only, weakly
            return { it, i, s: base > 0 ? base + Math.min(it.boost ?? 0, 20) * 0.4 : 0 };
        })
            .filter(x => x.s > 0)
            .sort((a, b) => b.s - a.s || a.i - b.i)      // ties keep source order: apps before tools
            .map(x => x.it);
    }

    // ---- sources: { key, title, sub, kind, icon | glyph, act(), confirm? } ----
    // Built once per change of installed apps or launch counts, not per keystroke:
    // mapping every desktop entry with icon lookups made the first open take ~2 s
    readonly property var appItems: DesktopEntries.applications.values.filter(e => !e.noDisplay).map(e => ({
            key: "app:" + e.id, title: e.name, sub: e.genericName || e.comment || "", kind: "App",
            icon: Quickshell.iconPath(e.icon, true), keys: (e.keywords ?? []).join(" ") + " " + e.id,
            ids: [e.id.toLowerCase().replace(/\.desktop$/, ""), (e.command?.[0] ?? "").split("/").pop().toLowerCase()].filter(x => x),
            boost: Store.usage[e.id] ?? 0,
            act: () => { Store.bump(e.id); e.execute(); }
        })).sort((a, b) => b.boost - a.boost || a.title.localeCompare(b.title))
    function apps() { return appItems; }
    function windows() {
        return Niri.windowList.map(w => ({
            key: "win:" + w.id, title: w.title || w.app_id, sub: w.app_id, kind: "Window", focused: w.is_focused,
            icon: Quickshell.iconPath(w.app_id, true) || Quickshell.iconPath((w.app_id ?? "").toLowerCase(), true),
            act: () => Niri.focusWindow(w.id)
        }));
    }
    function tools() {
        return [
            { key: "t:ocr", title: "Read text from the screen", sub: "Drag a region; the text is copied", kind: "Tool", glyph: "document_scanner", keys: "ocr text", act: () => Tools.ocr() },
            { key: "t:qr", title: "Scan a QR code", sub: "Drag over it; links open, the rest is copied", kind: "Tool", glyph: "qr_code_scanner", keys: "qr scan barcode", act: () => Tools.qrScan() },
            { key: "t:qrmake", title: "Clipboard as QR", sub: "Big enough for the phone camera", kind: "Tool", glyph: "qr_code_2", keys: "qr make clipboard", stay: true, act: () => Tools.qrFromClipboard() },
            { key: "t:color", title: "Pick a colour", sub: "Copies the hex value", kind: "Tool", glyph: "colorize", keys: "color colour picker hex", act: () => Tools.pickColor() },
            { key: "t:rec", title: Recorder.recording ? "Stop recording" : "Record the screen", sub: Recorder.recording ? Recorder.elapsedText : "Super+Shift+R · on the Intel iGPU", kind: "Tool", glyph: Recorder.recording ? "stop_circle" : "screen_record", keys: "record video capture", act: () => Recorder.toggle(Niri.focusedOutput) },
            { key: "t:wall", title: "Wallpapers", sub: "Pick a background", kind: "Tool", glyph: "wallpaper", keys: "wallpaper background change", stay: true, act: () => { Ui.section = "wallpapers"; } },
            { key: "t:recr", title: "Record a region", sub: "Drag to choose", kind: "Tool", glyph: "crop", keys: "record region video", act: () => Recorder.startRegion() }
        ];
    }
    function wallpapers() {
        return Wallpaper.files.map(f => {
            const name = f.replace(/^.*\//, "").replace(/\.[^.]*$/, "");
            return { key: "w:" + f, path: f, title: name, sub: f === Wallpaper.path ? "Current" : "", kind: "Wallpaper", icon: "file://" + f,
                     keys: "wallpaper background", act: () => Wallpaper.set(f) };
        });
    }
    function phone() {
        const tasks = [
            { key: "p:mirror", title: "Mirror phone", sub: "NectarLink", glyph: "cast", task: "mirror", keys: "screen" },
            { key: "p:ring", title: "Ring phone", sub: "Find it", glyph: "vibration", task: "find-phone", keys: "find" },
            { key: "p:clip", title: "Send clipboard to phone", sub: "", glyph: "content_paste_go", task: "send-clipboard" },
            { key: "p:photo", title: "Take a photo with the phone", sub: "Lands on the clipboard", glyph: "photo_camera", task: "take-photo", keys: "camera" },
            { key: "p:files", title: "Send files to phone", sub: "", glyph: "upload_file", task: "send-files" }
        ].map(t => Object.assign(t, { kind: "Phone", act: () => Tools.phone(t.task) }));
        const apps = Tools.phoneApps.map(a => ({
            key: "pa:" + a.pkg, title: a.label, sub: "Phone app", kind: "Phone", icon: Tools.phoneIcon(a.pkg), keys: a.pkg,
            act: () => Tools.phone("open-app:" + a.pkg)
        }));
        return tasks.concat(apps);
    }
    function clipboard() {
        return Tools.clips.map(c => ({
            key: "c:" + c.id, title: c.preview.replace(/\s+/g, " "), sub: "", kind: "Clip", glyph: "content_paste",
            act: () => Tools.pasteClip(c.id)
        }));
    }
    function inbox() {
        return Store.history.map((h, i) => ({
            key: "n:" + h.time + i, index: i, app: h.app || "Other", title: h.summary || h.app,
            sub: (h.body ?? "").replace(/\s+/g, " "),
            kind: Qt.formatTime(new Date(h.time), "HH:mm"), glyph: "notifications",
            act: () => { const n = Notifs.live(h.id); if (n) Notifs.activate(n); }
        }));
    }
    // Grouped by app (most recently active first); a few per app until expanded
    property var expanded: ({})
    function inboxGroups(q) {
        const groups = new Map();
        for (const it of ranked(inbox(), q)) {
            if (!groups.has(it.app)) groups.set(it.app, []);
            groups.get(it.app).push(it);
        }
        const out = [];
        for (const [app, list] of groups) {
            out.push({ header: app + " · " + list.length, key: "h:" + app });
            const shown = expanded[app] || q ? list : list.slice(0, Tune.limitInboxGroup);
            shown.forEach(i => out.push(i));
            if (shown.length < list.length) out.push({
                key: "more:" + app, title: "Show " + (list.length - shown.length) + " more", sub: "", kind: "", glyph: "expand_more", stay: true,
                act: () => { const e = Object.assign({}, expanded); e[app] = true; expanded = e; }
            });
        }
        return out;
    }
    function system() {
        return [
            { key: "s:suspend", title: "Suspend", sub: "Sleep now", glyph: "bedtime", keys: "sleep", act: () => Quickshell.execDetached(["systemctl", "suspend"]) },
            { key: "s:logout", title: "Log out", sub: "Quit niri", glyph: "logout", keys: "exit quit", confirm: true, act: () => Quickshell.execDetached(["niri", "msg", "action", "quit", "--skip-confirmation"]) },
            { key: "s:reboot", title: "Restart", sub: "", glyph: "restart_alt", keys: "reboot", confirm: true, act: () => Quickshell.execDetached(["systemctl", "reboot"]) },
            { key: "s:off", title: "Power off", sub: "", glyph: "power_settings_new", keys: "shutdown", confirm: true, act: () => Quickshell.execDetached(["systemctl", "poweroff"]) }
        ].map(s => Object.assign(s, { kind: "System" }));
    }

    // The main view: a few per category, under a small heading each
    function grouped(q) {
        const out = [];
        const add = (label, items) => {
            if (!items.length) return;
            out.push({ header: label, key: "h:" + label });
            items.forEach(i => out.push(i));
        };
        if (!q) {
            add("Apps & tools", apps().slice(0, Tune.limitAppsTools));
            add("Windows", windows().filter(w => !w.focused).slice(0, Tune.limitWindows));
            add("Phone", phone().slice(0, Tune.limitPhone));
        } else {
            add("Apps & tools", ranked(apps().concat(tools(), system()), q).slice(0, Tune.limitAppsTools));
            add("Windows", ranked(windows(), q).slice(0, Tune.limitWindows));
            add("Phone", ranked(phone(), q).slice(0, Tune.limitPhone));
        }
        return out;
    }

    readonly property string q: query.trim().toLowerCase()
    readonly property bool calcShown: Tools.calcAnswer !== "" && Tools.looksLikeCalc(query)
    readonly property var results: {
        // keep the list while the menu fades out; only drop it once hidden
        if (!visible) return [];
        const s = Ui.section;
        let list;
        if (s === "apps") list = ranked(apps(), q);
        else if (s === "windows") list = ranked(windows(), q);
        else if (s === "tools") list = ranked(tools(), q);
        else if (s === "phone") list = ranked(phone(), q);
        else if (s === "clipboard") list = ranked(clipboard(), q);
        else if (s === "wallpapers") list = ranked(wallpapers(), q);
        else if (s === "inbox") list = inboxGroups(q);
        else if (s === "system") list = ranked(system(), q);
        else list = grouped(q);
        return list.slice(0, 60);
    }

    // Headings aren't selectable: ↑↓ skip them
    function stepSel(dir) {
        let i = sel + dir;
        while (i >= 0 && i < results.length && results[i].header) i += dir;
        if (i >= 0 && i < results.length) sel = i;
    }
    function resetSel() { sel = 0; fixSel(); }
    function fixSel() {
        if (results[sel] && !results[sel].header) return;
        sel = Math.max(0, results.findIndex(r => !r.header));
    }
    // Keep the selection in view: at the very top show the heading above it too
    function reveal() {
        if (results.findIndex(r => !r.header) === sel) list.positionViewAtBeginning();
        else list.positionViewAtIndex(sel, ListView.Contain);
    }
    onResultsChanged: { fixSel(); Qt.callLater(reveal); }
    onSelChanged: { reveal(); if (open && Ui.section === "wallpapers") previewTimer.restart(); }
    Timer { id: previewTimer; interval: 280; onTriggered: Wallpaper.preview(root.results[root.sel]?.path) }

    function run(item) {
        if (!item || item.header) return;
        if (item.confirm && confirmKey !== item.key) { confirmKey = item.key; return; }
        item.act();
        if (!item.stay) Ui.close();
    }

    // ---- layout ----
    Column {
        anchors.fill: parent
        anchors.margins: 22
        spacing: 12

        Row {
            width: parent.width
            spacing: 12
            Text {
                text: "eco"
                font.family: Tune.iconFont
                font.pixelSize: 26
                color: Ambience.phase === "night" ? Tune.ember : Tune.sun
                anchors.verticalCenter: parent.verticalCenter
            }
            TextInput {
                id: input
                width: parent.width - 40
                anchors.verticalCenter: parent.verticalCenter
                font.family: Tune.displayFont
                font.pixelSize: 26
                color: Tune.parch
                selectionColor: Qt.rgba(Tune.sun.r, Tune.sun.g, Tune.sun.b, 0.35)
                clip: true
                onTextChanged: { root.query = text; root.resetSel(); root.confirmKey = ""; root.showQr = false; Tools.calc(text); }
                Text {
                    text: "What do you need?"
                    visible: !input.text
                    font: input.font
                    color: Qt.rgba(Tune.parch.r, Tune.parch.g, Tune.parch.b, 0.3)
                }
                Keys.onPressed: event => {
                    const n = root.results.length;
                    if (event.key === Qt.Key_Escape) {
                        if (root.showQr) root.showQr = false; else Ui.close();
                    } else if (event.key === Qt.Key_Down || (event.key === Qt.Key_Right && Ui.section === "wallpapers")) {
                        root.stepSel(1);
                    } else if (event.key === Qt.Key_Up || (event.key === Qt.Key_Left && Ui.section === "wallpapers")) {
                        root.stepSel(-1);
                    } else if (event.key === Qt.Key_Tab) {
                        root.cycle(1);
                    } else if (event.key === Qt.Key_Backtab) {
                        root.cycle(-1);
                    } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                        if (root.calcShown) { Tools.copy(Tools.calcAnswer.replace(/^.*= */, "")); Ui.close(); }
                        else root.run(root.results[root.sel]);
                    } else if (event.key === Qt.Key_Delete && Ui.section === "inbox" && root.results[root.sel]?.index !== undefined) {
                        const it = root.results[root.sel];
                        if (event.modifiers & Qt.ControlModifier) Store.forgetApp(it.app); else Store.forget(it.index);
                    } else {
                        return;
                    }
                    event.accepted = true;
                }
            }
        }

        // sections: a highlight that slides between them; click the lit one to clear the filter
        Item {
            id: tabs
            width: parent.width
            height: 26
            property real hx: 0
            property real hw: 0
            readonly property bool anyOn: Ui.section !== "all"

            Rectangle {
                height: 26
                radius: 13
                x: tabs.hx
                width: tabs.hw
                opacity: tabs.anyOn ? 1 : 0
                color: Qt.rgba(Tune.sun.r, Tune.sun.g, Tune.sun.b, 0.2)
                Behavior on x { NumberAnimation { duration: Tune.settle; easing.type: Easing.OutBack; easing.overshoot: 1.2 } }
                Behavior on width { NumberAnimation { duration: Tune.settle; easing.type: Easing.OutBack; easing.overshoot: 1.2 } }
                Behavior on opacity { NumberAnimation { duration: 200 } }
            }
            Row {
                spacing: 6
                Repeater {
                    model: root.sections
                    Item {
                        id: tab
                        required property var modelData
                        readonly property bool on: Ui.section === modelData.id
                        width: tabText.implicitWidth + 22
                        height: 26
                        function sync() { if (on) { tabs.hx = x; tabs.hw = width; } }
                        onOnChanged: sync()
                        onXChanged: sync()
                        onWidthChanged: sync()
                        Component.onCompleted: sync()
                        Text {
                            id: tabText
                            anchors.centerIn: parent
                            text: tab.modelData.label + (tab.modelData.id === "inbox" && Notifs.unread ? " · " + Notifs.unread : "")
                            font.family: Tune.uiFont
                            font.pixelSize: 12
                            font.weight: Font.DemiBold
                            color: tab.on ? Tune.sun : Qt.rgba(Tune.parch.r, Tune.parch.g, Tune.parch.b, 0.6)
                            Behavior on color { ColorAnimation { duration: 200 } }
                        }
                        TapHandler { onTapped: { Ui.section = tab.on ? "all" : tab.modelData.id; input.forceActiveFocus(); } }
                    }
                }
            }
        }

        // maths / units answer
        Column {
            visible: root.calcShown && !root.showQr
            width: parent.width
            spacing: 2
            Text {
                text: root.query
                font.family: Tune.uiFont
                font.pixelSize: 12
                color: Qt.rgba(Tune.parch.r, Tune.parch.g, Tune.parch.b, 0.6)
            }
            Text {
                width: parent.width
                text: Tools.calcAnswer.replace(/^.*= */, "")
                font.family: Tune.displayFont
                font.pixelSize: 44
                color: Ambience.phase === "night" ? Tune.ember : Tune.sun
                elide: Text.ElideRight
            }
            Text {
                text: "Enter copies it"
                font.family: Tune.uiFont
                font.pixelSize: 11
                color: Qt.rgba(Tune.parch.r, Tune.parch.g, Tune.parch.b, 0.5)
            }
        }

        // clipboard as QR
        Item {
            visible: root.showQr
            width: parent.width
            height: 300
            Image {
                anchors.centerIn: parent
                width: 280; height: 280
                source: root.showQr ? "file://" + Tools.qrFile + "?" + Tools.qrVersion : ""
                cache: false
                smooth: false
                fillMode: Image.PreserveAspectFit
            }
        }

        ListView {
            id: list
            visible: !root.showQr && Ui.section !== "wallpapers"
            width: parent.width
            height: parent.height - y
            clip: true
            model: root.results
            currentIndex: root.sel
            highlightMoveDuration: 120
            boundsBehavior: Flickable.StopAtBounds
            spacing: 2
            transform: Translate { id: listShift }

            delegate: Rectangle {
                id: row
                required property var modelData
                required property int index
                readonly property bool isHeader: !!modelData.header
                readonly property bool on: !isHeader && index === root.sel
                width: ListView.view.width
                height: isHeader ? 26 : 46
                radius: 14
                color: on ? Qt.rgba(Tune.parch.r, Tune.parch.g, Tune.parch.b, 0.08) : "transparent"

                Text {
                    visible: row.isHeader
                    x: 12
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 3
                    text: row.isHeader ? row.modelData.header.toUpperCase() : ""
                    font.family: Tune.uiFont
                    font.pixelSize: 10
                    font.weight: Font.Bold
                    font.letterSpacing: 1.3
                    color: Qt.rgba(Tune.sun.r, Tune.sun.g, Tune.sun.b, 0.75)
                }
                Rectangle {
                    id: ic
                    visible: !row.isHeader
                    x: 8
                    anchors.verticalCenter: parent.verticalCenter
                    width: 30; height: 30
                    topLeftRadius: 13; topRightRadius: 16; bottomRightRadius: 14; bottomLeftRadius: 15
                    color: row.modelData.icon ? "transparent" : Qt.rgba(Tune.sun.r, Tune.sun.g, Tune.sun.b, 0.16)
                    Image {
                        anchors.fill: parent
                        source: row.isHeader ? "" : (row.modelData.icon ?? "")
                        sourceSize: Qt.size(60, 60)
                        asynchronous: true
                        visible: !row.isHeader && !!row.modelData.icon
                    }
                    Text {
                        anchors.centerIn: parent
                        visible: !row.isHeader && !row.modelData.icon
                        text: row.isHeader ? "" : (row.modelData.glyph ?? "circle")
                        font.family: Tune.iconFont
                        font.pixelSize: 18
                        color: Tune.sun
                    }
                }
                Column {
                    visible: !row.isHeader
                    x: 50
                    width: parent.width - x - kind.width - 22
                    anchors.verticalCenter: parent.verticalCenter
                    Text {
                        width: parent.width
                        text: row.isHeader ? "" : root.confirmKey === row.modelData.key ? "Press Enter again to " + row.modelData.title.toLowerCase() : row.modelData.title
                        font.family: Tune.uiFont
                        font.pixelSize: 14
                        font.weight: Font.DemiBold
                        color: !row.isHeader && root.confirmKey === row.modelData.key ? Tune.ember : Tune.parch
                        elide: Text.ElideRight
                    }
                    Text {
                        width: parent.width
                        text: row.isHeader ? "" : (row.modelData.sub ?? "")
                        visible: text.length > 0
                        font.family: Tune.uiFont
                        font.pixelSize: 11
                        color: Qt.rgba(Tune.parch.r, Tune.parch.g, Tune.parch.b, 0.55)
                        elide: Text.ElideRight
                    }
                }
                Text {
                    id: kind
                    visible: !row.isHeader
                    anchors.right: parent.right
                    anchors.rightMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    text: row.isHeader ? "" : (row.modelData.kind ?? "")
                    font.family: Tune.uiFont
                    font.pixelSize: 11
                    font.weight: Font.DemiBold
                    color: Qt.rgba(Tune.parch.r, Tune.parch.g, Tune.parch.b, 0.4)
                }
                HoverHandler { enabled: !row.isHeader; onHoveredChanged: if (hovered) root.sel = row.index }
                TapHandler { enabled: !row.isHeader; onTapped: root.run(row.modelData) }
            }

            Text {
                anchors.centerIn: parent
                visible: list.count === 0 && !root.calcShown
                text: Ui.section === "inbox" ? "Nothing new. The forest is quiet."
                    : Ui.section === "clipboard" ? "The clipboard history is empty."
                    : Ui.section === "wallpapers" ? "No images in the wallpapers folder."
                    : "Nothing grew here. Try some maths, or another section."
                font.family: Tune.uiFont
                font.pixelSize: 13
                color: Qt.rgba(Tune.parch.r, Tune.parch.g, Tune.parch.b, 0.5)
            }
        }
    }

    // wallpapers: a filmstrip, the chosen one opens up; moving over one previews it live
    ListView {
        id: strip
        visible: Ui.section === "wallpapers" && !root.showQr
        anchors { left: parent.left; right: parent.right; leftMargin: 22; rightMargin: 22 }
        y: 130
        height: 250
        orientation: ListView.Horizontal
        spacing: 10
        clip: true
        model: Ui.section === "wallpapers" ? root.results : []
        currentIndex: root.sel
        highlightMoveDuration: 220
        highlightRangeMode: ListView.ApplyRange
        preferredHighlightBegin: 40
        preferredHighlightEnd: width - 260
        boundsBehavior: Flickable.StopAtBounds

        delegate: Item {
            id: card
            required property var modelData
            required property int index
            readonly property bool on: index === root.sel
            width: on ? 270 : 120
            height: strip.height
            Behavior on width { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }

            Image {
                id: img
                anchors.fill: frame
                source: card.modelData.icon ?? ""
                sourceSize: Qt.size(540, 500)
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                visible: false
            }
            Rectangle { id: msk; anchors.fill: frame; radius: 22; layer.enabled: true; visible: false }
            Rectangle {
                id: frame
                anchors { fill: parent; topMargin: card.on ? 0 : 24; bottomMargin: card.on ? 0 : 24 }
                radius: 22
                color: Qt.rgba(0.07, 0.1, 0.09, 0.8)
                Behavior on anchors.topMargin { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
                Behavior on anchors.bottomMargin { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
            }
            MultiEffect {
                anchors.fill: frame
                source: img
                maskEnabled: true
                maskSource: msk
                opacity: card.on ? 1 : 0.7
                Behavior on opacity { NumberAnimation { duration: 200 } }
            }
            Rectangle {
                anchors.fill: frame
                radius: 22
                color: "transparent"
                border.width: card.on ? 2 : 0
                border.color: Tune.sun
            }
            Text {
                visible: card.on
                anchors { left: frame.left; right: frame.right; bottom: frame.bottom; margins: 14 }
                text: card.modelData.title + (card.modelData.sub ? "  ·  " + card.modelData.sub : "")
                font.family: Tune.uiFont
                font.pixelSize: 12
                font.weight: Font.DemiBold
                color: Tune.parch
                elide: Text.ElideRight
                style: Text.Outline
                styleColor: Qt.rgba(0, 0, 0, 0.6)
            }
            HoverHandler { onHoveredChanged: if (hovered) root.sel = card.index }
            TapHandler { onTapped: root.run(card.modelData) }
        }
    }

    Text {
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 10
        anchors.horizontalCenter: parent.horizontalCenter
        text: Ui.section === "inbox" ? "↑↓ move · Enter open · Delete forgets · Ctrl+Delete clears the app · Esc close"
            : Ui.section === "wallpapers" ? "←→ browse · Enter keep · Esc put it back"
            : "↑↓ move · Enter open · Tab filters · Esc close"
        font.family: Tune.uiFont
        font.pixelSize: 11
        color: Qt.rgba(Tune.parch.r, Tune.parch.g, Tune.parch.b, 0.4)
    }
}
