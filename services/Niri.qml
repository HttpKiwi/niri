pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

/**
 * Niri - workspaces and windows straight from $NIRI_SOCKET's event stream.
 * No plugin (v1 depended on one living in v1's folder).
 */
Singleton {
    id: root

    property var workspaces: []   // sorted by output, then idx
    property var windows: ({})    // id -> window
    property bool overview: false
    readonly property string focusedOutput: workspaces.find(w => w.is_focused)?.output ?? ""

    // Workspaces worth a light on `output`: anything with windows, plus the active one
    function workspacesOn(output) {
        return workspaces.filter(w => w.output === output && (w.is_active || w.windows > 0));
    }

    // A window as large as the screen on that screen's active workspace
    function fullscreenOn(output, width, height) {
        const ws = workspaces.find(w => w.output === output && w.is_active);
        if (!ws || ws.active_window_id === null) return false;
        const win = windows[ws.active_window_id];
        const size = win?.layout?.tile_size;
        return !!size && size[0] >= width && size[1] >= height;
    }

    // Windows cover this screen's backdrop (life is pointless) unless the overview shows it
    function backdropHiddenOn(output) {
        if (overview) return false;
        const ws = workspaces.find(w => w.output === output && w.is_active);
        return !!ws && ws.windows > 0;
    }

    function focusWorkspace(id) {
        request({ Action: { FocusWorkspace: { reference: { Id: id } } } });
    }

    // ---- internals ----
    function _countWindows(list) {
        const counts = {};
        for (const id in windows) {
            const w = windows[id];
            counts[w.workspace_id] = (counts[w.workspace_id] ?? 0) + 1;
        }
        return list
            .map(w => Object.assign({}, w, { windows: counts[w.id] ?? 0 }))
            .sort((a, b) => a.output.localeCompare(b.output) || a.idx - b.idx);
    }
    function _setWindows(map) {
        windows = map;
        workspaces = _countWindows(workspaces);
    }

    function _handle(ev) {
        if (ev.WorkspacesChanged) {
            workspaces = _countWindows(ev.WorkspacesChanged.workspaces);
        } else if (ev.WorkspaceActivated) {
            const { id, focused } = ev.WorkspaceActivated;
            const out = workspaces.find(w => w.id === id)?.output;
            workspaces = workspaces.map(w => Object.assign({}, w, {
                is_active: w.output === out ? w.id === id : w.is_active,
                is_focused: focused ? w.id === id : w.is_focused
            }));
        } else if (ev.WorkspaceActiveWindowChanged) {
            const { workspace_id, active_window_id } = ev.WorkspaceActiveWindowChanged;
            workspaces = workspaces.map(w => w.id === workspace_id ? Object.assign({}, w, { active_window_id }) : w);
        } else if (ev.WindowsChanged) {
            const map = {};
            for (const w of ev.WindowsChanged.windows) map[w.id] = w;
            _setWindows(map);
        } else if (ev.WindowOpenedOrChanged) {
            const w = ev.WindowOpenedOrChanged.window;
            _setWindows(Object.assign({}, windows, { [w.id]: w }));
        } else if (ev.WindowClosed) {
            const map = Object.assign({}, windows);
            delete map[ev.WindowClosed.id];
            _setWindows(map);
        } else if (ev.WindowLayoutsChanged) {
            const map = Object.assign({}, windows);
            for (const [id, layout] of ev.WindowLayoutsChanged.changes)
                if (map[id]) map[id] = Object.assign({}, map[id], { layout });
            windows = map;
        } else if (ev.OverviewOpenedOrClosed) {
            overview = ev.OverviewOpenedOrClosed.is_open;
        }
    }

    Socket {
        id: events
        path: Quickshell.env("NIRI_SOCKET")
        connected: true
        onConnectedChanged: {
            if (connected) {
                write('"EventStream"\n');
                flush();
            } else {
                reconnect.start();
            }
        }
        parser: SplitParser {
            onRead: line => {
                try {
                    root._handle(JSON.parse(line));
                } catch (e) {
                    console.warn("Niri: bad event", e);
                }
            }
        }
    }
    Timer {
        id: reconnect
        interval: 1000
        onTriggered: events.connected = true
    }

    // One-shot requests: niri answers and closes, so each gets a fresh socket
    function request(obj) {
        const s = requestComponent.createObject(root, { payload: JSON.stringify(obj) + "\n" });
        s.connected = true;
    }
    Component {
        id: requestComponent
        Socket {
            id: req
            property string payload
            path: Quickshell.env("NIRI_SOCKET")
            onConnectedChanged: {
                if (connected) {
                    write(payload);
                    flush();
                } else {
                    destroy();
                }
            }
            parser: SplitParser {
                onRead: line => {
                    if (!line.includes('"Ok"')) console.warn("Niri:", line);
                    req.connected = false;
                }
            }
        }
    }
}
