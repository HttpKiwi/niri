pragma ComponentBehavior: Bound

import QtQuick
import qs.config
import qs.services

/**
 * Phone - its own pebble for the NectarLink phone: the actions (mirror, ring,
 * clipboard, photo, files) first, then the phone's apps as a grid. Type to
 * filter, arrows move, Enter runs, Esc closes.
 */
FocusScope {
    id: root

    required property bool open
    property string query: ""
    property int sel: 0
    readonly property int cols: 6

    readonly property var cells: {
        const acts = [
            { label: "Mirror", glyph: "cast", keys: "screen", run: () => Tools.phone("mirror") },
            { label: "Ring", glyph: "vibration", keys: "find locate", run: () => Tools.phone("find-phone") },
            { label: "Clipboard", glyph: "content_paste_go", keys: "send paste", run: () => Tools.phone("send-clipboard") },
            { label: "Photo", glyph: "photo_camera", keys: "camera take", run: () => Tools.phone("take-photo") },
            { label: "Files", glyph: "upload_file", keys: "send upload", run: () => Tools.phone("send-files") }
        ];
        const apps = Tools.phoneApps.map(a => ({ label: a.label, icon: Tools.phoneIcon(a.pkg), keys: a.pkg, run: () => Tools.phone("open-app:" + a.pkg) }));
        const q = query.trim().toLowerCase();
        const all = acts.concat(apps);
        return q ? all.filter(c => (c.label + " " + c.keys).toLowerCase().includes(q)) : all;
    }

    onOpenChanged: {
        if (!open) return;
        input.text = "";
        query = "";
        sel = 0;
        Tools.loadPhoneApps();
        input.forceActiveFocus();
    }
    onCellsChanged: sel = Math.min(sel, Math.max(0, cells.length - 1))
    onSelChanged: grid.positionViewAtIndex(sel, GridView.Contain)

    function run(i) {
        const c = cells[i];
        if (!c) return;
        c.run();
        Ui.close();
    }

    Row {
        x: 26; y: 22
        width: parent.width - 52
        spacing: 12
        Text {
            text: "smartphone"
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
                text: "Your phone"
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
                else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) root.run(root.sel);
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
        cellHeight: 92
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
                anchors { fill: parent; margins: 3 }
                radius: 16
                color: cell.on ? Qt.rgba(Tune.parch.r, Tune.parch.g, Tune.parch.b, 0.09) : "transparent"
            }
            Rectangle {
                id: ic
                anchors { horizontalCenter: parent.horizontalCenter; top: parent.top; topMargin: 10 }
                width: 46; height: 46
                topLeftRadius: 19; topRightRadius: 22; bottomRightRadius: 20; bottomLeftRadius: 21
                color: cell.modelData.icon ? "transparent" : Qt.rgba(Tune.sun.r, Tune.sun.g, Tune.sun.b, 0.18)
                Image {
                    anchors.fill: parent
                    visible: !!cell.modelData.icon && status === Image.Ready
                    source: cell.modelData.icon ?? ""
                    sourceSize: Qt.size(92, 92)
                    asynchronous: true
                }
                Text {
                    anchors.centerIn: parent
                    visible: !cell.modelData.icon
                    text: cell.modelData.glyph ?? "apps"
                    font.family: Tune.iconFont
                    font.pixelSize: 26
                    color: Tune.sun
                }
            }
            Text {
                anchors { left: parent.left; right: parent.right; top: ic.bottom; topMargin: 6; leftMargin: 4; rightMargin: 4 }
                horizontalAlignment: Text.AlignHCenter
                text: cell.modelData.label
                font.family: Tune.uiFont
                font.pixelSize: 11
                font.weight: Font.DemiBold
                color: Tune.parch
                elide: Text.ElideRight
            }
            HoverHandler { onHoveredChanged: if (hovered) root.sel = cell.index }
            TapHandler { onTapped: root.run(cell.index) }
        }

        Text {
            anchors.centerIn: parent
            visible: root.cells.length === 0
            text: "Nothing like that on the phone."
            font.family: Tune.uiFont
            font.pixelSize: 13
            color: Qt.rgba(Tune.parch.r, Tune.parch.g, Tune.parch.b, 0.5)
        }
    }

    Text {
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 10
        anchors.horizontalCenter: parent.horizontalCenter
        text: "arrows move · Enter opens · type to filter · Esc close"
        font.family: Tune.uiFont
        font.pixelSize: 11
        color: Qt.rgba(Tune.parch.r, Tune.parch.g, Tune.parch.b, 0.4)
    }
}
