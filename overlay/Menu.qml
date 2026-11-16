pragma ComponentBehavior: Bound

import QtQuick
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
        { id: "all", label: "Everything" }, { id: "apps", label: "Apps" },
        { id: "windows", label: "Windows" }, { id: "tools", label: "Tools" },
        { id: "phone", label: "Phone" }, { id: "clipboard", label: "Clipboard" },
        { id: "inbox", label: "Inbox" }, { id: "system", label: "System" }
    ]
    property string query: ""
    property int sel: 0
    property string confirmKey: ""     // a dangerous item waiting for a second Enter
    property bool showQr: false

    onOpenChanged: {
        if (!open) return;
        input.text = "";
        sel = 0;
        confirmKey = "";
        showQr = false;
        if (Ui.section === "clipboard") Tools.loadClips();
        if (Ui.section === "phone" || Ui.section === "all") Tools.loadPhoneApps();
        if (Ui.section === "inbox") Notifs.markRead();
        focusTimer.restart();
    }
    Timer { id: focusTimer; interval: 60; onTriggered: input.forceActiveFocus() }
    Connections {
        target: Ui
        function onSectionChanged() {
            root.sel = 0;
            root.confirmKey = "";
            if (Ui.section === "clipboard") Tools.loadClips();
            if (Ui.section === "phone") Tools.loadPhoneApps();
            if (Ui.section === "inbox") Notifs.markRead();
        }
    }
    Connections {
        target: Tools
        function onQrReady() { root.showQr = true; }
    }

    // ---- matching ----
    function score(text, q) {
        if (!q) return 1;
        const t = (text ?? "").toLowerCase();
        if (t.startsWith(q)) return 100 - t.length * 0.05;
        if (t.split(/[\s\-_.\/]+/).some(w => w.startsWith(q))) return 60;
        if (t.includes(q)) return 40;
        let i = 0;
        for (const c of t) if (c === q[i]) i++;
        return i === q.length ? 10 : 0;
    }
    function ranked(items, q) {
        if (!q) return items;
        return items.map(it => ({ it, s: Math.max(score(it.title, q), score(it.keys ?? "", q) * 0.9, score(it.sub, q) * 0.5) }))
            .filter(x => x.s > 0)
            .sort((a, b) => b.s - a.s || (b.it.boost ?? 0) - (a.it.boost ?? 0))
            .map(x => x.it);
    }

    // ---- sources: { key, title, sub, kind, icon | glyph, act(), confirm? } ----
    // Built once per change of installed apps or launch counts, not per keystroke:
    // mapping every desktop entry with icon lookups made the first open take ~2 s
    readonly property var appItems: DesktopEntries.applications.values.filter(e => !e.noDisplay).map(e => ({
            key: "app:" + e.id, title: e.name, sub: e.genericName || e.comment || "", kind: "App",
            icon: Quickshell.iconPath(e.icon, true), keys: (e.keywords ?? []).join(" ") + " " + e.id,
            boost: Store.usage[e.id] ?? 0,
            act: () => { Store.bump(e.id); e.execute(); }
        })).sort((a, b) => b.boost - a.boost || a.title.localeCompare(b.title))
    function apps() { return appItems; }
    function windows() {
        return Niri.windowList.map(w => ({
            key: "win:" + w.id, title: w.title || w.app_id, sub: w.app_id, kind: "Window",
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
            { key: "t:recr", title: "Record a region", sub: "Drag to choose", kind: "Tool", glyph: "crop", keys: "record region video", act: () => Recorder.startRegion() }
        ];
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
            key: "n:" + h.time + i, index: i, title: h.summary || h.app, sub: [h.app, (h.body ?? "").replace(/\s+/g, " ")].filter(x => x).join(" · "),
            kind: Qt.formatTime(new Date(h.time), "HH:mm"), glyph: "notifications",
            act: () => { const n = Notifs.live(h.id); if (n) Notifs.activate(n); }
        }));
    }
    function system() {
        return [
            { key: "s:suspend", title: "Suspend", sub: "Sleep now", glyph: "bedtime", keys: "sleep", act: () => Quickshell.execDetached(["systemctl", "suspend"]) },
            { key: "s:logout", title: "Log out", sub: "Quit niri", glyph: "logout", keys: "exit quit", confirm: true, act: () => Quickshell.execDetached(["niri", "msg", "action", "quit", "--skip-confirmation"]) },
            { key: "s:reboot", title: "Restart", sub: "", glyph: "restart_alt", keys: "reboot", confirm: true, act: () => Quickshell.execDetached(["systemctl", "reboot"]) },
            { key: "s:off", title: "Power off", sub: "", glyph: "power_settings_new", keys: "shutdown", confirm: true, act: () => Quickshell.execDetached(["systemctl", "poweroff"]) }
        ].map(s => Object.assign(s, { kind: "System" }));
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
        else if (s === "inbox") list = ranked(inbox(), q);
        else if (s === "system") list = ranked(system(), q);
        else if (!q) list = apps().slice(0, 4).concat(windows().slice(0, 2), inbox().slice(0, 2));
        else list = ranked(apps().concat(windows(), tools(), phone(), system()), q);
        return list.slice(0, 60);
    }
    onResultsChanged: if (sel >= results.length) sel = Math.max(0, results.length - 1)

    function run(item) {
        if (!item) return;
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
                onTextChanged: { root.query = text; root.sel = 0; root.confirmKey = ""; root.showQr = false; Tools.calc(text); }
                Text {
                    text: "What do you need?"
                    visible: !input.text
                    font: input.font
                    color: Qt.rgba(Tune.parch.r, Tune.parch.g, Tune.parch.b, 0.3)
                }
                Keys.onPressed: event => {
                    const n = root.results.length;
                    const idx = root.sections.findIndex(s => s.id === Ui.section);
                    if (event.key === Qt.Key_Escape) {
                        if (root.showQr) root.showQr = false; else Ui.close();
                    } else if (event.key === Qt.Key_Down) {
                        root.sel = Math.min(n - 1, root.sel + 1);
                    } else if (event.key === Qt.Key_Up) {
                        root.sel = Math.max(0, root.sel - 1);
                    } else if (event.key === Qt.Key_Tab) {
                        Ui.section = root.sections[(idx + 1) % root.sections.length].id;
                    } else if (event.key === Qt.Key_Backtab) {
                        Ui.section = root.sections[(idx - 1 + root.sections.length) % root.sections.length].id;
                    } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                        if (root.calcShown) { Tools.copy(Tools.calcAnswer.replace(/^.*= */, "")); Ui.close(); }
                        else root.run(root.results[root.sel]);
                    } else if (event.key === Qt.Key_Delete && Ui.section === "inbox" && root.results[root.sel]) {
                        Store.forget(root.results[root.sel].index);
                    } else {
                        return;
                    }
                    event.accepted = true;
                }
            }
        }

        // sections
        Flow {
            width: parent.width
            spacing: 6
            Repeater {
                model: root.sections
                Rectangle {
                    id: tab
                    required property var modelData
                    readonly property bool on: Ui.section === modelData.id
                    width: tabText.implicitWidth + 22
                    height: 26
                    radius: 13
                    color: on ? Qt.rgba(Tune.sun.r, Tune.sun.g, Tune.sun.b, 0.18) : Qt.rgba(Tune.parch.r, Tune.parch.g, Tune.parch.b, 0.05)
                    Text {
                        id: tabText
                        anchors.centerIn: parent
                        text: tab.modelData.label + (tab.modelData.id === "inbox" && Notifs.unread ? " · " + Notifs.unread : "")
                        font.family: Tune.uiFont
                        font.pixelSize: 12
                        font.weight: Font.DemiBold
                        color: tab.on ? Tune.sun : Qt.rgba(Tune.parch.r, Tune.parch.g, Tune.parch.b, 0.6)
                    }
                    TapHandler { onTapped: { Ui.section = tab.modelData.id; input.forceActiveFocus(); } }
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
            visible: !root.showQr
            width: parent.width
            height: parent.height - y
            clip: true
            model: root.results
            currentIndex: root.sel
            highlightMoveDuration: 120
            boundsBehavior: Flickable.StopAtBounds
            spacing: 2

            delegate: Rectangle {
                id: row
                required property var modelData
                required property int index
                readonly property bool on: index === root.sel
                width: ListView.view.width
                height: 46
                radius: 14
                color: on ? Qt.rgba(Tune.parch.r, Tune.parch.g, Tune.parch.b, 0.08) : "transparent"

                Rectangle {
                    id: ic
                    x: 8
                    anchors.verticalCenter: parent.verticalCenter
                    width: 30; height: 30
                    topLeftRadius: 13; topRightRadius: 16; bottomRightRadius: 14; bottomLeftRadius: 15
                    color: row.modelData.icon ? "transparent" : Qt.rgba(Tune.sun.r, Tune.sun.g, Tune.sun.b, 0.16)
                    Image {
                        anchors.fill: parent
                        source: row.modelData.icon ?? ""
                        sourceSize: Qt.size(60, 60)
                        asynchronous: true
                        visible: !!row.modelData.icon
                    }
                    Text {
                        anchors.centerIn: parent
                        visible: !row.modelData.icon
                        text: row.modelData.glyph ?? "circle"
                        font.family: Tune.iconFont
                        font.pixelSize: 18
                        color: Tune.sun
                    }
                }
                Column {
                    x: 50
                    width: parent.width - x - kind.width - 22
                    anchors.verticalCenter: parent.verticalCenter
                    Text {
                        width: parent.width
                        text: root.confirmKey === row.modelData.key ? "Press Enter again to " + row.modelData.title.toLowerCase() : row.modelData.title
                        font.family: Tune.uiFont
                        font.pixelSize: 14
                        font.weight: Font.DemiBold
                        color: root.confirmKey === row.modelData.key ? Tune.ember : Tune.parch
                        elide: Text.ElideRight
                    }
                    Text {
                        width: parent.width
                        text: row.modelData.sub ?? ""
                        visible: text.length > 0
                        font.family: Tune.uiFont
                        font.pixelSize: 11
                        color: Qt.rgba(Tune.parch.r, Tune.parch.g, Tune.parch.b, 0.55)
                        elide: Text.ElideRight
                    }
                }
                Text {
                    id: kind
                    anchors.right: parent.right
                    anchors.rightMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    text: row.modelData.kind ?? ""
                    font.family: Tune.uiFont
                    font.pixelSize: 11
                    font.weight: Font.DemiBold
                    color: Qt.rgba(Tune.parch.r, Tune.parch.g, Tune.parch.b, 0.4)
                }
                HoverHandler { onHoveredChanged: if (hovered) root.sel = row.index }
                TapHandler { onTapped: root.run(row.modelData) }
            }

            Text {
                anchors.centerIn: parent
                visible: list.count === 0 && !root.calcShown
                text: Ui.section === "inbox" ? "Nothing new. The forest is quiet."
                    : Ui.section === "clipboard" ? "The clipboard history is empty."
                    : "Nothing grew here. Try some maths, or another section."
                font.family: Tune.uiFont
                font.pixelSize: 13
                color: Qt.rgba(Tune.parch.r, Tune.parch.g, Tune.parch.b, 0.5)
            }
        }
    }

    Text {
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 10
        anchors.horizontalCenter: parent.horizontalCenter
        text: Ui.section === "inbox" ? "↑↓ move · Enter open · Delete forget · Tab section · Esc close"
            : "↑↓ move · Enter open · Tab section · Esc close"
        font.family: Tune.uiFont
        font.pixelSize: 11
        color: Qt.rgba(Tune.parch.r, Tune.parch.g, Tune.parch.b, 0.4)
    }
}
