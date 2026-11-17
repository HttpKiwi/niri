pragma ComponentBehavior: Bound

import QtQuick
import qs.config
import qs.services

/**
 * Inbox - the notifications, in a pebble of their own: grouped by app, newest
 * app first. ↑↓ move, Enter opens, Delete forgets one, Ctrl+Delete clears the
 * app, Esc closes. No search: it's a place to glance, not to look things up.
 */
FocusScope {
    id: root

    required property bool open
    property int sel: 0
    property var expanded: ({})

    // flat, in group order; apps keep the order of their newest notification
    readonly property var groups: {
        const m = new Map();
        Store.history.forEach((h, i) => {
            const app = h.app || "Other";
            if (!m.has(app)) m.set(app, []);
            m.get(app).push({ app, index: i, id: h.id, title: h.summary || app,
                              body: (h.body ?? "").replace(/\s+/g, " "), time: h.time });
        });
        return m;
    }
    readonly property var entries: {
        const out = [];
        for (const [app, list] of groups) {
            const shown = expanded[app] ? list : list.slice(0, Tune.limitInboxGroup);
            shown.forEach(n => out.push(n));
            if (shown.length < list.length) out.push({ app, more: list.length - shown.length });
        }
        return out;
    }
    function total(app) { return groups.get(app)?.length ?? 0; }

    onOpenChanged: {
        if (!open) return;
        expanded = ({});
        sel = 0;
        Notifs.markRead();
        forceActiveFocus();
    }
    onEntriesChanged: sel = Math.min(sel, Math.max(0, entries.length - 1))
    onSelChanged: Qt.callLater(() => list.positionViewAtIndex(sel, ListView.Contain))

    function act(e) {
        if (!e) return;
        if (e.more) {
            const x = Object.assign({}, expanded);
            x[e.app] = true;
            expanded = x;
        } else {
            const n = Notifs.live(e.id);
            if (n) { Notifs.activate(n); Ui.close(); }
        }
    }

    Keys.onPressed: event => {
        const e = entries[sel];
        if (event.key === Qt.Key_Escape) Ui.close();
        else if (event.key === Qt.Key_Down) sel = Math.min(entries.length - 1, sel + 1);
        else if (event.key === Qt.Key_Up) sel = Math.max(0, sel - 1);
        else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) act(e);
        else if (event.key === Qt.Key_Delete && e) {
            if (e.more || (event.modifiers & Qt.ControlModifier)) Store.forgetApp(e.app);
            else Store.forget(e.index);
        } else return;
        event.accepted = true;
    }

    Row {
        x: 26; y: 22
        spacing: 10
        Text {
            text: "notifications"
            font.family: Tune.iconFont
            font.pixelSize: 24
            color: Ambience.phase === "night" ? Tune.ember : Tune.sun
            anchors.verticalCenter: parent.verticalCenter
        }
        Text {
            text: "Notifications"
            font.family: Tune.displayFont
            font.pixelSize: 24
            color: Tune.parch
        }
    }
    // clear everything
    Rectangle {
        visible: root.entries.length > 0
        anchors { right: parent.right; rightMargin: 24; top: parent.top; topMargin: 26 }
        width: clearText.implicitWidth + 24
        height: 28
        radius: 14
        color: clearHover.hovered ? Qt.rgba(Tune.ember.r, Tune.ember.g, Tune.ember.b, 0.22) : Qt.rgba(Tune.parch.r, Tune.parch.g, Tune.parch.b, 0.08)
        Behavior on color { ColorAnimation { duration: 150 } }
        Text {
            id: clearText
            anchors.centerIn: parent
            text: "Clear all"
            font.family: Tune.uiFont
            font.pixelSize: 12
            font.weight: Font.DemiBold
            color: Tune.parch
        }
        HoverHandler { id: clearHover; cursorShape: Qt.PointingHandCursor }
        TapHandler { onTapped: Store.forgetAll() }
    }

    ListView {
        id: list
        anchors { fill: parent; topMargin: 70; bottomMargin: 34; leftMargin: 16; rightMargin: 16 }
        clip: true
        model: root.entries
        spacing: 2
        boundsBehavior: Flickable.StopAtBounds

        section.property: "app"
        section.delegate: Item {
            id: head
            required property string section
            width: ListView.view.width
            height: 34
            Text {
                x: 12
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 5
                text: head.section.toUpperCase() + " · " + root.total(head.section)
                font.family: Tune.uiFont
                font.pixelSize: 10
                font.weight: Font.Bold
                font.letterSpacing: 1.3
                color: Qt.rgba(Tune.sun.r, Tune.sun.g, Tune.sun.b, 0.75)
            }
        }

        delegate: Rectangle {
            id: row
            required property var modelData
            required property int index
            readonly property bool on: index === root.sel
            width: ListView.view.width
            height: modelData.more ? 36 : 58
            radius: 14
            color: on ? Qt.rgba(Tune.parch.r, Tune.parch.g, Tune.parch.b, 0.09) : "transparent"

            // a notification
            Column {
                visible: !row.modelData.more
                x: 14
                width: parent.width - x - time.width - 24
                anchors.verticalCenter: parent.verticalCenter
                spacing: 1
                Text {
                    width: parent.width
                    text: row.modelData.title ?? ""
                    font.family: Tune.uiFont
                    font.pixelSize: 13
                    font.weight: Font.DemiBold
                    color: Tune.parch
                    elide: Text.ElideRight
                }
                Text {
                    width: parent.width
                    text: row.modelData.body ?? ""
                    visible: text.length > 0
                    font.family: Tune.uiFont
                    font.pixelSize: 11
                    color: Qt.rgba(Tune.parch.r, Tune.parch.g, Tune.parch.b, 0.6)
                    elide: Text.ElideRight
                }
            }
            Text {
                id: time
                visible: !row.modelData.more
                anchors { right: parent.right; rightMargin: 14; verticalCenter: parent.verticalCenter }
                text: row.modelData.time ? Qt.formatTime(new Date(row.modelData.time), "HH:mm") : ""
                font.family: Tune.uiFont
                font.pixelSize: 11
                color: Qt.rgba(Tune.parch.r, Tune.parch.g, Tune.parch.b, 0.4)
            }
            // "show more"
            Text {
                visible: !!row.modelData.more
                x: 14
                anchors.verticalCenter: parent.verticalCenter
                text: "Show " + row.modelData.more + " more"
                font.family: Tune.uiFont
                font.pixelSize: 12
                font.weight: Font.DemiBold
                color: Qt.rgba(Tune.sun.r, Tune.sun.g, Tune.sun.b, 0.85)
            }
            HoverHandler { onHoveredChanged: if (hovered) root.sel = row.index }
            TapHandler { onTapped: root.act(row.modelData) }
        }

        Text {
            anchors.centerIn: parent
            visible: root.entries.length === 0
            text: "Nothing new. The forest is quiet."
            font.family: Tune.uiFont
            font.pixelSize: 13
            color: Qt.rgba(Tune.parch.r, Tune.parch.g, Tune.parch.b, 0.5)
        }
    }

    Text {
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 10
        anchors.horizontalCenter: parent.horizontalCenter
        text: "↑↓ move · Enter open · Delete forgets · Ctrl+Delete clears the app · Esc close"
        font.family: Tune.uiFont
        font.pixelSize: 11
        color: Qt.rgba(Tune.parch.r, Tune.parch.g, Tune.parch.b, 0.4)
    }
}
