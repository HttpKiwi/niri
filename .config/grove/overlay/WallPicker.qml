pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import qs.config
import qs.services

/**
 * WallPicker - its own pebble for choosing the wallpaper: a filmstrip where the
 * chosen one opens up. Moving over one previews it live; Enter keeps it, Esc
 * (or closing) puts the saved one back.
 */
FocusScope {
    id: root

    required property bool open
    property int sel: 0
    readonly property var items: Wallpaper.files.map(f => ({
        path: f, title: f.replace(/^.*\//, "").replace(/\.[^.]*$/, ""), current: f === Wallpaper.saved }))

    onOpenChanged: {
        if (open) {
            Wallpaper.load();
            sel = Math.max(0, items.findIndex(i => i.current));
            forceActiveFocus();
        } else {
            preview.stop();
            Wallpaper.revert();
        }
    }
    // the list loads after opening: start on the current one
    onItemsChanged: if (open && sel === 0) sel = Math.max(0, items.findIndex(i => i.current))
    onSelChanged: if (open) preview.restart()
    Timer { id: preview; interval: 280; onTriggered: Wallpaper.preview(root.items[root.sel]?.path) }

    function keep(i) {
        const it = items[i];
        if (!it) return;
        Wallpaper.set(it.path);
        Ui.close();
    }

    Keys.onPressed: event => {
        if (event.key === Qt.Key_Escape) Ui.close();
        else if (event.key === Qt.Key_Right || event.key === Qt.Key_Down) sel = Math.min(items.length - 1, sel + 1);
        else if (event.key === Qt.Key_Left || event.key === Qt.Key_Up) sel = Math.max(0, sel - 1);
        else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) keep(sel);
        else return;
        event.accepted = true;
    }

    Text {
        x: 26; y: 20
        text: "Wallpapers"
        font.family: Tune.displayFont
        font.pixelSize: 24
        color: Tune.parch
    }
    Text {
        anchors { left: parent.left; right: parent.right; leftMargin: 26; rightMargin: 26; top: parent.top; topMargin: 26 }
        horizontalAlignment: Text.AlignRight
        text: root.items.length ? (root.sel + 1) + " / " + root.items.length : ""
        font.family: Tune.uiFont
        font.pixelSize: 12
        color: Qt.rgba(Tune.parch.r, Tune.parch.g, Tune.parch.b, 0.45)
    }

    ListView {
        id: strip
        anchors { left: parent.left; right: parent.right; leftMargin: 22; rightMargin: 22; top: parent.top; topMargin: 64 }
        height: parent.height - 64 - 36
        orientation: ListView.Horizontal
        spacing: 10
        clip: true
        model: root.items
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
                source: "file://" + card.modelData.path
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
                text: card.modelData.title + (card.modelData.current ? "  ·  Current" : "")
                font.family: Tune.uiFont
                font.pixelSize: 12
                font.weight: Font.DemiBold
                color: Tune.parch
                elide: Text.ElideRight
                style: Text.Outline
                styleColor: Qt.rgba(0, 0, 0, 0.6)
            }
            HoverHandler { onHoveredChanged: if (hovered) root.sel = card.index }
            TapHandler { onTapped: root.keep(card.index) }
        }
    }

    Text {
        visible: root.items.length === 0
        anchors.centerIn: parent
        text: "No images in the wallpapers folder."
        font.family: Tune.uiFont
        font.pixelSize: 13
        color: Qt.rgba(Tune.parch.r, Tune.parch.g, Tune.parch.b, 0.5)
    }
    Text {
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 10
        anchors.horizontalCenter: parent.horizontalCenter
        text: "←→ browse · Enter keep · Esc put it back"
        font.family: Tune.uiFont
        font.pixelSize: 11
        color: Qt.rgba(Tune.parch.r, Tune.parch.g, Tune.parch.b, 0.4)
    }
}
