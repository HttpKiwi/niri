pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Services.Notifications
import Quickshell.Io
import QtQuick

/**
 * NotificationService - D-Bus notifications via Quickshell NotificationServer.
 * Keeps live Notification objects so NotificationAction.invoke() works (official API).
 */
Item {
    id: root

    // String(id) → live Notification
    property var liveById: ({})

    signal notificationReceived(var notification)

    NotificationServer {
        id: notificationServer

        actionsSupported: true
        bodyMarkupSupported: true
        imageSupported: true

        onNotification: function(notification) {
            notification.tracked = true;

            const id = String(notification.id);
            const map = Object.assign({}, root.liveById);
            map[id] = notification;
            root.liveById = map;

            notification.closed.connect(function() {
                root._dropLive(id);
            });

            console.log(
                "Received notification:", notification.summary,
                "desktopEntry:", notification.desktopEntry || "(none)",
                "actions:", notification.actions?.length || 0
            );

            root.notificationReceived(notification);
        }
    }

    function getLive(id) {
        if (id === undefined || id === null)
            return null;
        return root.liveById[String(id)] || null;
    }

    function _dropLive(id) {
        const key = String(id);
        if (!root.liveById[key])
            return;
        const map = Object.assign({}, root.liveById);
        delete map[key];
        root.liveById = map;
    }

    function release(id) {
        const live = getLive(id);
        if (live) {
            try {
                live.tracked = false;
            } catch (e) {}
        }
        _dropLive(id);
    }

    /**
     * Activate notification (open chat/app) then dismiss from UI.
     * Uses official NotificationAction.invoke() on the live Notification.
     */
    function activate(data) {
        if (!data)
            return;

        const id = String(data.id ?? "");
        const live = getLive(id);
        let invoked = false;

        if (live && live.actions && live.actions.length > 0) {
            let action = null;
            for (let i = 0; i < live.actions.length; i++) {
                const a = live.actions[i];
                if (a && a.identifier === "default") {
                    action = a;
                    break;
                }
            }
            if (!action)
                action = live.actions[0];

            if (action && action.invoke) {
                try {
                    action.invoke();
                    invoked = true;
                    console.log("NotificationService: invoked action", action.identifier || action.text, "for", id);
                } catch (e) {
                    console.warn("NotificationService: invoke failed:", e);
                }
            }
        }

        if (!invoked) {
            const key = (data.desktopEntry || live?.desktopEntry || data.appName || "").toString();
            focusApp(key);
        }

        // invoke() dismisses non-resident notifications; always clear our UI
        dismissUi(id);
    }

    /**
     * Invoke a specific live action by index, then dismiss UI.
     */
    function activateAction(data, actionIndex) {
        if (!data)
            return
        const id = String(data.id ?? "")
        const live = getLive(id)
        if (live?.actions && live.actions[actionIndex]?.invoke) {
            try {
                live.actions[actionIndex].invoke()
            } catch (e) {
                console.warn("NotificationService: action invoke failed:", e)
            }
            dismissUi(id)
            return
        }

        // Stored action label only (live handle expired) — fall back to app focus
        if (data.actions && data.actions[actionIndex]) {
            console.warn("NotificationService: action no longer live, focusing app for", id)
            activate(data)
            return
        }

        activate(data)
    }

    /**
     * Remove popup only — keep entry in control-center history.
     * Used for timeout / swipe-away on the popup.
     */
    function hidePopup(id, expired) {
        const key = String(id)
        // Remove from popup stack only — keep live notification for control-center actions
        NotificationModel.removeById(key)
    }

    /**
     * Full dismiss: popup + history (activate click, history swipe, clear).
     */
    function dismissUi(id) {
        const key = String(id);
        release(key);
        NotificationModel.removeById(key);
        NotificationStore.dismissNotification(key);
    }

    function dismissOnly(id) {
        const key = String(id);
        const live = getLive(key);
        if (live) {
            try {
                live.dismiss();
            } catch (e) {
                try { live.tracked = false; } catch (e2) {}
            }
        }
        dismissUi(key);
    }

    // --- niri focus fallback ---
    property string _focusQuery: ""

    Process {
        id: windowsProcess
        running: false
        stdout: StdioCollector {
            id: windowsStdout
            onStreamFinished: {
                root._focusFromWindowsJson(windowsStdout.text, root._focusQuery);
            }
        }
    }

    function focusApp(desktopEntryOrAppName) {
        const q = (desktopEntryOrAppName || "").toString().trim();
        if (!q) {
            console.warn("NotificationService: no desktopEntry/appName to focus");
            return;
        }
        root._focusQuery = q;
        windowsProcess.command = ["niri", "msg", "-j", "windows"];
        windowsProcess.running = false;
        windowsProcess.running = true;
    }

    function _normalizeId(s) {
        return s.toString().trim().toLowerCase().replace(/\.desktop$/, "");
    }

    function _focusFromWindowsJson(text, query) {
        let windows = [];
        try {
            windows = JSON.parse(text || "[]");
        } catch (e) {
            console.warn("NotificationService: failed to parse niri windows:", e);
            return;
        }

        const q = _normalizeId(query);
        if (!q)
            return;

        let match = null;
        for (let i = 0; i < windows.length; i++) {
            const w = windows[i];
            const appId = _normalizeId(w.app_id || "");
            const title = (w.title || "").toLowerCase();
            if (appId && (appId === q || appId.includes(q) || q.includes(appId))) {
                match = w;
                break;
            }
            if (title && title.includes(q)) {
                match = w;
                break;
            }
        }

        if (!match || match.id === undefined) {
            console.warn("NotificationService: no window for", query);
            return;
        }

        console.log("NotificationService: focusing window", match.id, match.app_id, match.title);
        Quickshell.execDetached(["niri", "msg", "action", "focus-window", "--id", String(match.id)]);
    }
}
