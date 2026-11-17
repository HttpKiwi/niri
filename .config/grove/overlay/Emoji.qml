pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config
import qs.services

/**
 * Emoji - its own pebble: type a word, pick one, it lands on the clipboard.
 * Recents first. Data: data/emoji.json (bin/gen-emoji).
 */
FocusScope {
    id: root

    required property bool open
    property string query: ""
    property int sel: 0
    property var all: []
    readonly property int cols: 9

    FileView {
        id: file
        path: Quickshell.shellPath("data/emoji.json")
        blockLoading: true
        printErrors: false
        onLoaded: { try { root.all = JSON.parse(text()); } catch (e) { root.all = []; } }
    }

    readonly property var cells: {
        const q = query.trim().toLowerCase();
        if (q) {
            const words = q.split(/\s+/);
            return all.filter(e => words.every(w => e.n.includes(w))).slice(0, 180);
        }
        const recent = (Store.prefs.emojiRecent ?? []).map(c => all.find(e => e.c === c)).filter(e => e);
        const seen = new Set(recent.map(e => e.c));
        return recent.concat(all.filter(e => !seen.has(e.c))).slice(0, 180);
    }

    onOpenChanged: {
        if (!open) return;
        if (all.length === 0) file.reload();
        input.text = "";
        query = "";
        sel = 0;
        input.forceActiveFocus();
    }
    onCellsChanged: sel = Math.min(sel, Math.max(0, cells.length - 1))
    onSelChanged: grid.positionViewAtIndex(sel, GridView.Contain)

    function pick(i) {
        const e = cells[i];
        if (!e) return;
        Tools.copy(e.c);
        const r = [e.c].concat((Store.prefs.emojiRecent ?? []).filter(c => c !== e.c)).slice(0, 18);
        Store.setPref("emojiRecent", r);
        Ui.close();
    }

    Row {
        x: 26; y: 22
        width: parent.width - 52
        spacing: 12
        Text {
            text: "mood"
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
            onTextChanged: { root.query = text; root.sel = 0; }
            Text {
                text: "Find an emoji"
                visible: !input.text
                font: input.font
                color: Qt.rgba(Tune.parch.r, Tune.parch.g, Tune.parch.b, 0.3)
            }
            Keys.onPressed: event => {
                const n = root.cells.length;
                if (event.key === Qt.Key_Escape) Ui.close();
                else if (event.key === Qt.Key_Right) root.sel = Math.min(n - 1, root.sel + 1);
                else if (event.key === Qt.Key_Left) root.sel = Math.max(0, root.sel - 1);
                else if (event.key === Qt.Key_Down) root.sel = Math.min(n - 1, root.sel + root.cols);
                else if (event.key === Qt.Key_Up) root.sel = Math.max(0, root.sel - root.cols);
                else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) root.pick(root.sel);
                else return;
                event.accepted = true;
            }
        }
    }

    GridView {
        id: grid
        anchors { fill: parent; topMargin: 84; bottomMargin: 36; leftMargin: 20; rightMargin: 20 }
        clip: true
        cellWidth: Math.floor(width / root.cols)
        cellHeight: cellWidth
        model: root.cells
        boundsBehavior: Flickable.StopAtBounds

        delegate: Item {
            id: cell
            required property var modelData
            required property int index
            readonly property bool on: index === root.sel
            width: grid.cellWidth
            height: grid.cellHeight
            Rectangle {
                anchors { fill: parent; margins: 2 }
                radius: 14
                color: cell.on ? Qt.rgba(Tune.parch.r, Tune.parch.g, Tune.parch.b, 0.12) : "transparent"
            }
            Text {
                anchors.centerIn: parent
                text: cell.modelData.c
                font.family: "Noto Color Emoji"
                // a real font size, never a scale: scaled bitmap glyphs blur
                font.pixelSize: cell.on ? 34 : 30
            }
            HoverHandler { onHoveredChanged: if (hovered) root.sel = cell.index }
            TapHandler { onTapped: root.pick(cell.index) }
        }

        Text {
            anchors.centerIn: parent
            visible: root.cells.length === 0
            text: "No emoji by that name."
            font.family: Tune.uiFont
            font.pixelSize: 13
            color: Qt.rgba(Tune.parch.r, Tune.parch.g, Tune.parch.b, 0.5)
        }
    }

    Text {
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 10
        anchors.horizontalCenter: parent.horizontalCenter
        width: parent.width - 40
        horizontalAlignment: Text.AlignHCenter
        elide: Text.ElideRight
        text: root.cells[root.sel] ? root.cells[root.sel].n + "  ·  Enter copies" : "type to search"
        font.family: Tune.uiFont
        font.pixelSize: 11
        color: Qt.rgba(Tune.parch.r, Tune.parch.g, Tune.parch.b, 0.5)
    }
}
