import QtQuick
import qs.core
import qs.config

/**
 * WorkspaceMinimap - Tiny map of the active workspace's scrolling layout.
 * One rectangle per tiled window: columns side by side, tiles stacked,
 * sized from niri's tile sizes. Click a tile to focus that window.
 */
Item {
    id: root

    // niri output name of the bar's monitor
    required property string outputName
    property int mapHeight: Settings.barPillHeight - 8
    property int maxWidth: 120
    readonly property int gap: 2

    readonly property int workspaceId: Niri.activeWorkspaceIdFor(outputName)

    // Bumped on add/remove; property reads below track per-window layout changes
    property int _rev: 0

    readonly property var columns: {
        _rev;
        const cols = {};
        for (let i = 0; i < windowTracker.count; i++) {
            const w = windowTracker.objectAt(i)?.window;
            if (!w || w.isFloating || w.workspaceId !== workspaceId || w.columnIndex < 1)
                continue;
            (cols[w.columnIndex] = cols[w.columnIndex] || []).push(w);
        }
        return Object.keys(cols)
            .map(Number)
            .sort((a, b) => a - b)
            .map(k => cols[k].sort((a, b) => a.tileIndex - b.tileIndex));
    }

    readonly property int tileCount: columns.reduce((n, col) => n + col.length, 0)

    // One scale for the whole map so relative column widths stay true
    readonly property real scale: {
        let totalW = 0;
        let maxH = 1;
        for (const col of columns) {
            totalW += Math.max(...col.map(w => w.tileWidth));
            maxH = Math.max(maxH, col.reduce((h, w) => h + w.tileHeight, 0));
        }
        const usableW = maxWidth - gap * Math.max(0, columns.length - 1);
        return Math.min(mapHeight / maxH, totalW > 0 ? usableW / totalW : 1);
    }

    implicitWidth: columns.length ? Math.min(row.implicitWidth, maxWidth) : 0
    implicitHeight: mapHeight
    visible: columns.length > 0
    // niri can report transient sizes mid-switch; never draw outside the pill
    clip: true

    Instantiator {
        id: windowTracker
        model: Niri.windows
        delegate: QtObject {
            required property var modelData
            readonly property var window: modelData
        }
        onObjectAdded: root._rev++
        onObjectRemoved: root._rev++
    }

    Row {
        id: row
        anchors.verticalCenter: parent.verticalCenter
        spacing: root.gap

        Repeater {
            model: root.columns

            delegate: Column {
                id: column
                required property var modelData
                spacing: root.gap
                anchors.verticalCenter: parent ? parent.verticalCenter : undefined

                Repeater {
                    model: column.modelData

                    delegate: Rectangle {
                        required property var modelData
                        readonly property var win: modelData

                        width: Math.min(root.maxWidth, Math.max(3, Math.round(win.tileWidth * root.scale)))
                        height: Math.min(root.mapHeight, Math.max(3, Math.round(win.tileHeight * root.scale) - (column.modelData.length > 1 ? root.gap : 0)))
                        radius: 2
                        color: win.isFocused ? Theme.accent
                            : win.isUrgent ? Theme.error
                            : tileMouse.containsMouse ? Theme.withAlpha(Theme.textPrimary, 0.25)
                            : "transparent"
                        border.width: win.isFocused ? 0 : 1
                        border.color: win.isUrgent ? Theme.error : Theme.withAlpha(Theme.textPrimary, 0.45)

                        Behavior on color { ColorAnimation { duration: Settings.animationDurationShort } }

                        MouseArea {
                            id: tileMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Niri.focusWindow(parent.win.id)
                        }
                    }
                }
            }
        }
    }
}
