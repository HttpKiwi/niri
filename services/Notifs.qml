pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Notifications

/**
 * Notifs - Grove is the notification daemon. New notifications are announced
 * (`arrived`) for the island; `unread` counts them until you look (phase 4's
 * menu marks them read; for now clicking the seed does). History lives in
 * `list` (tracked notifications) until dismissed.
 */
Singleton {
    id: root

    readonly property var list: server.trackedNotifications.values
    property int unread: 0
    property int inFlight: 0     // shown as a message, mote not landed yet

    signal arrived(Notification n)

    function markRead() { unread = 0; }
    function activate(n) {
        const act = n.actions.find(a => a.identifier === "default") ?? null;
        if (act) act.invoke(); else n.dismiss();
    }

    NotificationServer {
        id: server
        keepOnReload: true
        actionsSupported: true
        bodySupported: true
        bodyMarkupSupported: false
        imageSupported: true
        persistenceSupported: true
        onNotification: n => {
            n.tracked = true;
            root.unread++;
            root.arrived(n);
        }
    }
}
