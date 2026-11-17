pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import qs.config
import qs.components.base

/**
 * PhonePanel - Left pocket driving NectarLink (patched build with the
 * `mirror` and `open-app:<pkg>` tasks). Apps and icons come from
 * NectarLink's own cache, so the list is whatever its Apps page last loaded.
 */
PocketSlidePanel {
    id: root

    panelFlag: "phone"
    slideFrom: "left"

    readonly property int panelWidth: 340
    readonly property int pad: 14
    readonly property string dataDir: Quickshell.env("HOME") + "/.local/share/Nectarlink"

    property var apps: []      // [{pkg, label}], recent first
    property var recent: []
    property string query: ""
    readonly property var shown: {
        const q = query.trim().toLowerCase();
        return q ? apps.filter(a => a.label.toLowerCase().includes(q) || a.pkg.includes(q)) : apps;
    }

    implicitWidth: panelWidth
    width: panelWidth

    function task(t) {
        Quickshell.execDetached(["nectarlink-desktop", "--task", t]);
        root.panelState.phone = false;
    }

    function sortApps(list) {
        const rank = p => {
            const i = recent.indexOf(p);
            return i < 0 ? 1e6 : i;
        };
        return list.slice().sort((a, b) => rank(a.pkg) - rank(b.pkg) || a.label.localeCompare(b.label));
    }

    onOpened: {
        query = "";
        search.text = "";
        appsProc.running = true;
        windowsFile.reload();
        Qt.callLater(() => search.forceActiveFocus());
    }

    // Recently opened phone apps, newest first
    FileView {
        id: windowsFile
        path: root.dataDir + "/app-windows.json"
        blockLoading: false
        onLoaded: {
            try {
                const r = JSON.parse(text()).recent ?? {};
                root.recent = Object.values(r)[0] ?? [];
            } catch (e) {
                root.recent = [];
            }
            root.apps = root.sortApps(root.apps);
        }
    }

    // One file per paired phone; this takes the first
    Process {
        id: appsProc
        command: ["sh", "-c", "cat \"$(ls \"$1\"/cache/apps/*.json | head -n 1)\"", "sh", root.dataDir]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.apps = root.sortApps(JSON.parse(text));
                } catch (e) {
                    root.apps = [];
                }
                grid.currentIndex = 0;
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: Settings.screenCornerRadius
        color: "transparent"

        Column {
            id: col
            anchors.fill: parent
            anchors.margins: root.pad
            spacing: 12

            Text {
                text: "Phone"
                color: Theme.textPrimary
                font.family: Settings.fontFamilyDefault
                font.pixelSize: Settings.fontSizeTitle
                font.weight: Font.DemiBold
            }

            // Quick actions
            Row {
                id: actions
                spacing: (col.width - 5 * 52) / 4

                Repeater {
                    model: [
                        { icon: "cast", label: "Mirror", task: "mirror" },
                        { icon: "vibration", label: "Ring", task: "find-phone" },
                        { icon: "content_paste_go", label: "Clipboard", task: "send-clipboard" },
                        { icon: "photo_camera", label: "Photo", task: "take-photo" },
                        { icon: "upload_file", label: "Files", task: "send-files" }
                    ]

                    delegate: Column {
                        id: action
                        required property var modelData
                        spacing: 4
                        width: 52

                        Rectangle {
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: 44
                            height: 44
                            radius: 22
                            color: actionArea.containsMouse ? Theme.accent : Theme.withAlpha(Theme.surfaceHighest, 0.85)

                            Text {
                                anchors.centerIn: parent
                                text: action.modelData.icon
                                color: actionArea.containsMouse ? Theme.textOnPrimary : Theme.textPrimary
                                font.family: Settings.fontFamilyIcons
                                font.pixelSize: 22
                            }

                            MouseArea {
                                id: actionArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.task(action.modelData.task)
                            }
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: action.modelData.label
                            color: Theme.textSecondary
                            font.family: Settings.fontFamilyDefault
                            font.pixelSize: Settings.fontSizeCaption
                        }
                    }
                }
            }

            TextField {
                id: search
                width: col.width
                placeholderText: "Search phone apps"
                color: Theme.textPrimary
                placeholderTextColor: Theme.textDisabled
                font.family: Settings.fontFamilyDefault
                font.pixelSize: Settings.fontSizeMedium
                background: Rectangle {
                    radius: height / 2
                    color: Theme.withAlpha(Theme.surfaceHighest, 0.85)
                }
                height: 36
                leftPadding: 14
                topPadding: 0
                bottomPadding: 0
                verticalAlignment: TextInput.AlignVCenter
                onTextChanged: {
                    root.query = text;
                    grid.currentIndex = 0;
                }

                Keys.onPressed: event => {
                    const cols = 4;
                    const n = root.shown.length;
                    if (event.key === Qt.Key_Escape) {
                        root.panelState.phone = false;
                    } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                        if (n > 0) root.task("open-app:" + root.shown[grid.currentIndex].pkg);
                    } else if (event.key === Qt.Key_M && (event.modifiers & Qt.ControlModifier)) {
                        root.task("mirror");
                    } else if (event.key === Qt.Key_Right) {
                        grid.currentIndex = Math.min(n - 1, grid.currentIndex + 1);
                    } else if (event.key === Qt.Key_Left) {
                        grid.currentIndex = Math.max(0, grid.currentIndex - 1);
                    } else if (event.key === Qt.Key_Down) {
                        grid.currentIndex = Math.min(n - 1, grid.currentIndex + cols);
                    } else if (event.key === Qt.Key_Up) {
                        grid.currentIndex = Math.max(0, grid.currentIndex - cols);
                    } else {
                        return;
                    }
                    event.accepted = true;
                }
            }

            GridView {
                id: grid
                width: col.width
                height: col.height - y - hint.height - col.spacing
                clip: true
                cellWidth: width / 4
                cellHeight: 84
                model: root.shown
                boundsBehavior: Flickable.StopAtBounds
                highlightMoveDuration: 0

                Text {
                    anchors.centerIn: parent
                    visible: root.apps.length === 0
                    width: parent.width - 20
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                    text: "No apps yet — open NectarLink's Apps page once to load them."
                    color: Theme.textSecondary
                    font.family: Settings.fontFamilyDefault
                    font.pixelSize: Settings.fontSizeSmall
                }

                delegate: Item {
                    id: cell
                    required property var modelData
                    required property int index
                    width: grid.cellWidth
                    height: grid.cellHeight
                    readonly property bool active: grid.currentIndex === index || cellArea.containsMouse

                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: 3
                        radius: Settings.cardRadius
                        color: cell.active ? Theme.withAlpha(Theme.accent, 0.18) : "transparent"
                    }

                    Image {
                        id: icon
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: 10
                        width: 44
                        height: 44
                        sourceSize: Qt.size(88, 88)
                        asynchronous: true
                        source: "file://" + root.dataDir + "/cache/icons/" + cell.modelData.pkg.replace(/[^A-Za-z0-9._]/g, "_") + ".png"
                    }

                    Text {
                        anchors.top: icon.bottom
                        anchors.topMargin: 6
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: parent.width - 8
                        horizontalAlignment: Text.AlignHCenter
                        elide: Text.ElideRight
                        text: cell.modelData.label
                        color: cell.active ? Theme.textPrimary : Theme.textSecondary
                        font.family: Settings.fontFamilyDefault
                        font.pixelSize: Settings.fontSizeCaption
                    }

                    MouseArea {
                        id: cellArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.task("open-app:" + cell.modelData.pkg)
                    }
                }
            }

            Text {
                id: hint
                text: "Super+P · Enter open · Ctrl+M mirror · Esc"
                color: Theme.withAlpha(Theme.textSecondary, 0.7)
                font.family: Settings.fontFamilyDefault
                font.pixelSize: Settings.fontSizeCaption
            }
        }
    }
}
