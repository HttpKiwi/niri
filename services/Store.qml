pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

/**
 * Store - the little state Grove keeps across restarts: app launch counts and
 * notification history. One file, written only after it has been read
 * (v1 lost data by saving before its load finished).
 */
Singleton {
    id: root

    property var usage: ({})      // desktop entry id -> launches
    property var history: []      // newest first: { id, app, summary, body, time }
    property bool loaded: false

    function bump(appId) {
        const u = Object.assign({}, usage);
        u[appId] = (u[appId] ?? 0) + 1;
        usage = u;
        save();
    }
    function remember(n) {
        history = [{ id: n.id, app: n.appName, summary: n.summary, body: n.body, time: Date.now() }]
            .concat(history).slice(0, Tune.historyMax);
        save();
    }
    function forget(index) {
        history = history.filter((_, i) => i !== index);
        save();
    }
    function forgetAll() { history = []; save(); }

    function save() {
        if (!loaded) return;
        saveTimer.restart();
    }
    Timer {
        id: saveTimer
        interval: 400
        onTriggered: file.setText(JSON.stringify({ usage: root.usage, history: root.history }))
    }

    FileView {
        id: file
        path: Tune.stateFile
        blockLoading: true
        atomicWrites: true
        printErrors: false
        onLoaded: {
            try {
                const d = JSON.parse(text());
                root.usage = d.usage ?? {};
                root.history = d.history ?? [];
            } catch (e) {
                console.warn("Store: unreadable state, starting fresh", e);
            }
            root.loaded = true;
        }
        // first run: no file yet
        onLoadFailed: root.loaded = true
    }
    Component.onCompleted: Quickshell.execDetached(["mkdir", "-p", Tune.stateFile.replace(/\/[^/]*$/, "")])
}
