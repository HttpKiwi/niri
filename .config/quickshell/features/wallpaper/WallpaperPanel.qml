pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import qs.config
import qs.core
import qs.components.base

PocketBottomPanel {
    id: root

    panelFlag: "wallpaper"
    bottomInset: 50
    animationDuration: Settings.animationDurationMedium
    easingType: Settings.easingStandard

    property var wallpapers: []
    property int selectedIndex: 0
    readonly property string wallpapersDir: Settings.wallpapersDir
    readonly property string currentWallpaperFile: Settings.currentWallpaperFile

    property string originalWallpaper: ""
    property bool isPreviewing: false
    property int previousSelectedIndex: 0
    property bool _userHasManuallySelected: false

    readonly property int thumbnailSize: 130
    readonly property int thumbnailSpacing: 8
    readonly property int expandedWidth: 230
    readonly property int panelHeight: thumbnailSize + 140
    readonly property int panelWidth: 1000

    anchors.horizontalCenter: parent.horizontalCenter
    anchors.bottom: parent.bottom
    implicitWidth: panelWidth
    implicitHeight: panelHeight
    focus: true

    onOpened: {
        originalWallpaper = Settings.backgroundImagePath;
        isPreviewing = false;
        _userHasManuallySelected = false;
        Qt.callLater(function() {
            root.forceActiveFocus();
            scrollToSelected();
        });
    }

    onClosed: {
        if (isPreviewing) {
            Settings.backgroundImagePath = originalWallpaper;
            if (originalWallpaper && originalWallpaper !== "")
                MatugenRunner.run(originalWallpaper);
            isPreviewing = false;
        }
    }

    Component.onCompleted: {
        wallpaperScanner.running = true;
    }

    Timer {
        id: wallpaperWatcher
        interval: 5000
        running: root.visible
        repeat: true
        onTriggered: {
            if (!wallpaperScanner.running) {
                wallpaperScanner.running = true;
            }
        }
    }

    Timer {
        id: wallpaperDebounce
        interval: 400
        property string pendingWallpaper: ""
        onTriggered: {
            if (pendingWallpaper && Settings.backgroundImagePath !== pendingWallpaper) {
                Settings.backgroundImagePath = pendingWallpaper;
            }
            pendingWallpaper = "";
        }
    }

    Process {
        id: wallpaperScanner
        command: ["sh", "-c", `find "${wallpapersDir}" -maxdepth 1 -type f \\( -name "*.jpg" -o -name "*.jpeg" -o -name "*.png" -o -name "*.webp" -o -name "*.gif" -o -name "*.mp4" -o -name "*.webm" -o -name "*.mkv" -o -name "*.mov" \\) ! -name "*current_wallpaper*" -print | sort`]
        running: false

        stdout: SplitParser {
            id: scannerOutput
            property string collectedOutput: ""
            onRead: function(data) {
                collectedOutput += data + "\n";
            }
        }

        onRunningChanged: {
            if (!running) {
                const output = scannerOutput.collectedOutput.trim();
                if (output) {
                    root.wallpapers = output.split('\n').map(function(path) {
                        const filename = path.split('/').pop();
                        const name = filename.replace(/\.[^/.]+$/, "");
                        return { path: path, name: name, filename: filename };
                    });
                    currentWallpaperLoader.running = true;
                }
                scannerOutput.collectedOutput = "";
            }
        }
    }

    Process {
        id: currentWallpaperLoader
        command: ["cat", currentWallpaperFile]
        running: false

        stdout: SplitParser {
            id: currentWallpaperOutput
            property string collectedOutput: ""
            onRead: function(data) {
                collectedOutput += data;
            }
        }

        onRunningChanged: {
            if (!running) {
                const output = currentWallpaperOutput.collectedOutput.trim();
                if (output && !_userHasManuallySelected) {
                    try {
                        const data = JSON.parse(output);
                        if (data.path) {
                            const idx = root.wallpapers.findIndex(function(w) { return w.path === data.path; });
                            if (idx !== -1) {
                                root.selectedIndex = idx;
                            }
                        }
                    } catch (e) {}
                }
                currentWallpaperOutput.collectedOutput = "";
            }
        }
    }

    Process {
        id: wallpaperSaver
        running: false
    }

    onSelectedIndexChanged: {
        if (wallpapers.length > 0 && selectedIndex >= 0 && selectedIndex < wallpapers.length) {
            const selectedWallpaper = wallpapers[selectedIndex];

            if (selectedIndex > previousSelectedIndex) {
                Settings.wallpaperChangeDirection = 1;
            } else if (selectedIndex < previousSelectedIndex) {
                Settings.wallpaperChangeDirection = -1;
            }
            previousSelectedIndex = selectedIndex;

            _userHasManuallySelected = true;
            isPreviewing = true;

            wallpaperDebounce.pendingWallpaper = selectedWallpaper.path;
            wallpaperDebounce.restart();

            MatugenRunner.run(selectedWallpaper.path);

            scrollToSelected();
        }
    }

    function regenerateCurrentWallpaper() {
        if (wallpapers.length > 0 && selectedIndex >= 0 && selectedIndex < wallpapers.length)
            MatugenRunner.run(wallpapers[selectedIndex].path);
    }

    Connections {
        target: MatugenPreferences
        function onSchemeTypeChanged() { regenerateCurrentWallpaper(); }
        function onColorModeChanged() { regenerateCurrentWallpaper(); }
        function onContrastLevelChanged() { regenerateCurrentWallpaper(); }
    }

    function scrollToSelected() {
        if (!scrollView || wallpapers.length === 0) return;

        let itemX = 8;
        for (let i = 0; i < selectedIndex; i++) {
            itemX += thumbnailSize + thumbnailSpacing;
        }
        itemX += expandedWidth / 2;

        const scrollViewCenter = scrollView.width / 2;
        const targetX = itemX - scrollViewCenter;
        const contentWidth = thumbnailRow.width;
        const viewWidth = scrollView.width;
        const maxScroll = Math.max(0, contentWidth - viewWidth);
        const scrollX = Math.max(0, Math.min(targetX, maxScroll));

        scrollView.ScrollBar.horizontal.position = scrollX / contentWidth;
    }

    function cancelPreview() {
        Settings.backgroundImagePath = originalWallpaper;
        if (originalWallpaper && originalWallpaper !== "")
            MatugenRunner.run(originalWallpaper);
        isPreviewing = false;
    }

    function applyWallpaper() {
        if (wallpapers.length === 0 || selectedIndex < 0 || selectedIndex >= wallpapers.length) return;

        const selectedWallpaper = wallpapers[selectedIndex];
        const jsonData = JSON.stringify({ path: selectedWallpaper.path });
        wallpaperSaver.command = ["sh", "-c", `echo '${jsonData}' > '${currentWallpaperFile}'`];
        wallpaperSaver.running = true;

        Settings.backgroundImagePath = selectedWallpaper.path;
        isPreviewing = false;

        panelState.wallpaper = false;
    }

    Keys.onPressed: function(event) {
        if (event.key === Qt.Key_Escape) {
            if (isPreviewing) cancelPreview();
            panelState.wallpaper = false;
            event.accepted = true;
        } else if (event.key === Qt.Key_Left) {
            if (selectedIndex > 0) selectedIndex--;
            event.accepted = true;
        } else if (event.key === Qt.Key_Right) {
            if (selectedIndex < wallpapers.length - 1) selectedIndex++;
            event.accepted = true;
        } else if (event.key === Qt.Key_S) {
            MatugenPreferences.nextScheme();
            event.accepted = true;
        } else if (event.key === Qt.Key_M) {
            MatugenPreferences.toggleMode();
            event.accepted = true;
        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            applyWallpaper();
            event.accepted = true;
        }
    }

    Rectangle {
        anchors.fill: parent
        color: Settings.chromeShaderEnabled ? "transparent" : Theme.surfaceBase
        radius: Settings.screenCornerRadius

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 8

            Text {
                Layout.fillWidth: true
                text: "Select Wallpaper"
                color: Theme.textPrimary
                font.pixelSize: Settings.fontSizeLarge
                font.weight: Font.Bold
                horizontalAlignment: Text.AlignHCenter
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 32
                spacing: 12

                Item { Layout.fillWidth: true }

                Rectangle {
                    Layout.preferredWidth: 180
                    Layout.preferredHeight: 32
                    color: Theme.cardBackground
                    radius: 8
                    border.color: Theme.borderDefault
                    border.width: 1

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: MatugenPreferences.nextScheme()

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 8
                            spacing: 6

                            Text {
                                text: "\uD83C\uDFA8"
                                font.pixelSize: Settings.fontSizeMedium
                            }

                            Text {
                                Layout.fillWidth: true
                                text: MatugenPreferences.schemeName
                                color: Theme.textPrimary
                                font.pixelSize: Settings.fontSizeSmall
                                elide: Text.ElideRight
                            }

                            Text {
                                text: "\u25BC"
                                color: Theme.textSecondary
                                font.pixelSize: Settings.fontSizeSmall
                            }
                        }
                    }
                }

                Rectangle {
                    Layout.preferredWidth: 80
                    Layout.preferredHeight: 32
                    color: Theme.cardBackground
                    radius: 8
                    border.color: Theme.borderDefault
                    border.width: 1

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: MatugenPreferences.toggleMode()

                        Text {
                            anchors.centerIn: parent
                            text: MatugenPreferences.colorMode === "dark" ? "\uD83C\uDF19 Dark" : "\u2600\uFE0F Light"
                            color: Theme.textPrimary
                            font.pixelSize: Settings.fontSizeSmall
                        }
                    }
                }

                Item { Layout.fillWidth: true }
            }

            ScrollView {
                id: scrollView
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true

                ScrollBar.horizontal.policy: ScrollBar.AsNeeded
                ScrollBar.vertical.policy: ScrollBar.AlwaysOff

                Behavior on ScrollBar.horizontal.position {
                    NumberAnimation {
                        duration: Settings.animationDurationMedium
                        easing.type: Settings.easingStandard
                    }
                }

                Row {
                    id: thumbnailRow
                    spacing: thumbnailSpacing
                    padding: 8

                    Repeater {
                        model: root.wallpapers

                        delegate: Item {
                            required property int index
                            required property var modelData

                            property bool isSelected: index === root.selectedIndex
                            property int currentWidth: thumbnailSize
                            property bool isVideo: {
                                const path = modelData.path.toLowerCase();
                                return path.endsWith('.mp4') || path.endsWith('.webm') ||
                                       path.endsWith('.mkv') || path.endsWith('.mov');
                            }

                            onIsSelectedChanged: {
                                currentWidth = isSelected ? expandedWidth : thumbnailSize;
                            }

                            width: currentWidth
                            height: thumbnailSize

                            Behavior on currentWidth {
                                NumberAnimation {
                                    duration: Settings.animationDurationMedium
                                    easing.type: Settings.easingStandard
                                }
                            }

                            Rectangle {
                                id: thumbFrame
                                anchors.fill: parent
                                anchors.margins: isSelected ? 8 : 0
                                color: Theme.cardBackground
                                radius: isSelected ? Settings.cardRadius + 4 : Settings.cardRadius
                                border.color: isSelected ? Theme.accent : Theme.borderDefault
                                border.width: isSelected ? 3 : 1

                                Behavior on border.color {
                                    ColorAnimation { duration: Settings.animationDurationShort }
                                }

                                Behavior on border.width {
                                    NumberAnimation { duration: Settings.animationDurationShort }
                                }

                                Behavior on anchors.margins {
                                    NumberAnimation {
                                        duration: Settings.animationDurationMedium
                                        easing.type: Settings.easingStandard
                                    }
                                }

                                // Rounded mask (clip alone is rectangular only)
                                Item {
                                    id: thumbMask
                                    anchors.fill: parent
                                    layer.enabled: true
                                    visible: false

                                    Rectangle {
                                        anchors.fill: parent
                                        radius: thumbFrame.radius
                                        color: "white"
                                    }
                                }

                                Image {
                                    id: thumbImage
                                    anchors.fill: parent
                                    source: "file://" + modelData.path
                                    fillMode: Image.PreserveAspectCrop
                                    smooth: true
                                    asynchronous: true
                                    cache: true
                                    visible: false
                                }

                                MultiEffect {
                                    anchors.fill: parent
                                    source: thumbImage
                                    maskEnabled: true
                                    maskSource: thumbMask
                                    visible: !isVideo
                                }

                                Rectangle {
                                    anchors.fill: parent
                                    radius: thumbFrame.radius
                                    color: "#88000000"
                                    visible: isVideo
                                    clip: true

                                    Text {
                                        anchors.centerIn: parent
                                        text: "\u25B6"
                                        font.pixelSize: 48
                                        color: "white"
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (index !== root.selectedIndex) {
                                            root.selectedIndex = index;
                                        } else {
                                            applyWallpaper();
                                        }
                                    }
                                }
                            }

                            Text {
                                anchors.top: parent.bottom
                                anchors.topMargin: 4
                                anchors.horizontalCenter: parent.horizontalCenter
                                width: parent.width
                                text: modelData.name
                                color: isSelected ? Theme.accent : Theme.textSecondary
                                font.pixelSize: Settings.fontSizeSmall
                                elide: Text.ElideMiddle
                                horizontalAlignment: Text.AlignHCenter
                                visible: !isSelected

                                Behavior on color {
                                    ColorAnimation { duration: Settings.animationDurationShort }
                                }
                            }
                        }
                    }

                    Text {
                        width: 400
                        height: thumbnailSize
                        text: "No wallpapers found in\n" + wallpapersDir
                        color: Theme.textSecondary
                        font.pixelSize: Settings.fontSizeMedium
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        visible: root.wallpapers.length === 0
                    }
                }
            }

            Text {
                Layout.fillWidth: true
                text: wallpapers.length > 0 && selectedIndex >= 0 && selectedIndex < wallpapers.length ?
                      "Selected: " + wallpapers[selectedIndex].name : "No selection"
                color: Theme.textPrimary
                font.pixelSize: Settings.fontSizeMedium
                horizontalAlignment: Text.AlignHCenter
            }
        }
    }
}
