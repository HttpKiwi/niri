pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import qs.config
import qs.components.base

/**
 * WallpaperSelector - Simple horizontal scrolling wallpaper selector
 * Features:
 * - Horizontal scrollable thumbnail view
 * - Click to apply wallpaper
 * - IPC toggle support
 * - Persists selection to current_wallpaper.json
 */

PanelWindow {
    id: wallpaperSelector

    // Wallpaper data
    property var wallpapers: []
    property int selectedIndex: 0
    property string wallpapersDir: "/home/httpkiwi/Pictures/Wallpapers"
    property string currentWallpaperFile: wallpapersDir + "/current_wallpaper.json"

    // UI state
    property bool _showAnimation: false
    property bool _isHiding: false
    property bool _completingHide: false

    // Dimensions
    readonly property int thumbnailSize: 200
    readonly property int thumbnailSpacing: 12
    readonly property int panelHeight: thumbnailSize + 80

    visible: false
    color: "transparent"
    exclusiveZone: -1
    implicitWidth: 800
    implicitHeight: panelHeight

    // Position at bottom center
    anchors {
        bottom: true
    }

    margins {
        bottom: 50
        left: (wallpaperSelector.screen?.width || 1920) / 2 - 400
        right: (wallpaperSelector.screen?.width || 1920) / 2 - 400
    }

    // Mask for rounded corners
    mask: Region {
        item: mainContainer
    }

    Component.onCompleted: {
        console.log("WallpaperSelector: Component completed")
        WlrLayershell.layer = WlrLayer.Overlay
        WlrLayershell.namespace = "quickshell-wallpaper-selector"
        // Start scanning for wallpapers
        wallpaperScanner.running = true
    }

    // Static Process for scanning wallpapers
    Process {
        id: wallpaperScanner
        command: ["sh", "-c", `find "${wallpapersDir}" -maxdepth 1 -type f \\( -name "*.jpg" -o -name "*.jpeg" -o -name "*.png" -o -name "*.webp" -o -name "*.gif" \\) ! -name "*current_wallpaper*" -print | sort`]
        running: false

        stdout: SplitParser {
            id: scannerOutput
            property string collectedOutput: ""

            onRead: data => {
                collectedOutput += data + "\n"
            }
        }

        onRunningChanged: {
            if (!running) {
                console.log("WallpaperSelector: Scanner finished")
                console.log("WallpaperSelector: stderr:", stderr)

                const output = scannerOutput.collectedOutput.trim()
                if (output) {
                    const lines = output.split('\n')
                    console.log("WallpaperSelector: Found", lines.length, "files")

                    wallpaperSelector.wallpapers = lines.map((path) => {
                        const filename = path.split('/').pop()
                        const name = filename.replace(/\.[^/.]+$/, "")
                        return {
                            path: path,
                            name: name,
                            filename: filename
                        }
                    })

                    console.log("WallpaperSelector: Loaded wallpapers:", JSON.stringify(wallpaperSelector.wallpapers))

                    // Load current wallpaper selection
                    currentWallpaperLoader.running = true
                } else {
                    console.log("WallpaperSelector: No wallpapers found")
                }

                // Reset for next scan
                scannerOutput.collectedOutput = ""
            }
        }
    }

    // Static Process for loading current wallpaper
    Process {
        id: currentWallpaperLoader
        command: ["cat", currentWallpaperFile]
        running: false

        stdout: SplitParser {
            id: currentWallpaperOutput
            property string collectedOutput: ""

            onRead: data => {
                collectedOutput += data
            }
        }

        onRunningChanged: {
            if (!running) {
                const output = currentWallpaperOutput.collectedOutput.trim()
                console.log("WallpaperSelector: Current wallpaper output:", output)
                if (output) {
                    try {
                        const data = JSON.parse(output)
                        console.log("WallpaperSelector: Current wallpaper data:", JSON.stringify(data))
                        if (data.path) {
                            const idx = wallpaperSelector.wallpapers.findIndex(w => w.path === data.path)
                            if (idx !== -1) {
                                wallpaperSelector.selectedIndex = idx
                                console.log("WallpaperSelector: Set selectedIndex to:", idx)
                            }
                        }
                    } catch (e) {
                        console.log("WallpaperSelector: Failed to parse JSON:", e)
                    }
                }

                // Reset for next load
                currentWallpaperOutput.collectedOutput = ""
            }
        }
    }

    // Static Process for saving wallpaper selection
    Process {
        id: wallpaperSaver
        running: false

        onRunningChanged: {
            if (!running) {
                console.log("WallpaperSelector: Wallpaper saved successfully")
            }
        }
    }

    onVisibleChanged: {
        console.log("WallpaperSelector: Visibility changed to:", visible)
        if (visible) {
            if (!_isHiding) {
                hideAnimationTimer.stop()
                WlrLayershell.keyboardFocus = WlrKeyboardFocus.Exclusive
                _showAnimation = false
                mainContainer.forceActiveFocus()
                Qt.callLater(() => {
                    _showAnimation = true
                    mainContainer.forceActiveFocus()
                })
            }
        } else {
            if (!_isHiding && !_completingHide) {
                Qt.callLater(() => {
                    if (!visible && !_isHiding && !_completingHide) {
                        _isHiding = true
                        _showAnimation = false
                        visible = true
                        WlrLayershell.keyboardFocus = WlrKeyboardFocus.None
                        hideAnimationTimer.restart()
                    }
                })
            }
        }
    }

    // Keyboard handling
    Keys.onPressed: (event) => {
        if (event.key === Qt.Key_Escape) {
            wallpaperSelector._showAnimation = false
            wallpaperSelector._isHiding = true
            hideAnimationTimer.restart()
            event.accepted = true
        } else if (event.key === Qt.Key_Left) {
            if (selectedIndex > 0) {
                selectedIndex--
            }
            event.accepted = true
        } else if (event.key === Qt.Key_Right) {
            if (selectedIndex < wallpapers.length - 1) {
                selectedIndex++
            }
            event.accepted = true
        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            applyWallpaper()
            event.accepted = true
        }
    }

    // Timer for hide animation
    Timer {
        id: hideAnimationTimer
        interval: Settings.animationDurationMedium
        onTriggered: {
            if (_isHiding) {
                _completingHide = true
                _isHiding = false
                visible = false
                Qt.callLater(() => {
                    _completingHide = false
                })
            }
        }
    }

    // IPC handler
    IpcHandler {
        function toggleSelector() {
            if (wallpaperSelector.visible) {
                wallpaperSelector._showAnimation = false
                wallpaperSelector._isHiding = true
                hideAnimationTimer.restart()
            } else {
                wallpaperSelector.visible = true
            }
        }

        target: "wallpaperSelector"
    }

    // Apply selected wallpaper
    function applyWallpaper() {
        console.log("WallpaperSelector: applyWallpaper called")
        console.log("WallpaperSelector: selectedIndex:", selectedIndex)
        console.log("WallpaperSelector: wallpapers.length:", wallpapers.length)

        if (wallpapers.length === 0 || selectedIndex < 0 || selectedIndex >= wallpapers.length) {
            console.log("WallpaperSelector: Cannot apply - invalid state")
            return
        }

        const selectedWallpaper = wallpapers[selectedIndex]
        console.log("WallpaperSelector: Selected wallpaper:", JSON.stringify(selectedWallpaper))

        // Save to JSON file
        const jsonData = JSON.stringify({ path: selectedWallpaper.path })
        wallpaperSaver.command = ["sh", "-c", `echo '${jsonData}' > '${currentWallpaperFile}'`]
        wallpaperSaver.running = true

        // Update Settings (this will trigger Background component to reload)
        Settings.backgroundImagePath = selectedWallpaper.path
        console.log("WallpaperSelector: Updated Settings.backgroundImagePath to:", selectedWallpaper.path)

        // Close selector with animation
        wallpaperSelector._showAnimation = false
        wallpaperSelector._isHiding = true
        hideAnimationTimer.restart()
    }

    // Main container
    Item {
        id: mainContainer
        anchors.fill: parent
        focus: true

        // Keyboard events
        Keys.onPressed: (event) => {
            if (event.key === Qt.Key_Escape) {
                wallpaperSelector._showAnimation = false
                wallpaperSelector._isHiding = true
                hideAnimationTimer.restart()
                event.accepted = true
            } else if (event.key === Qt.Key_Left) {
                if (selectedIndex > 0) {
                    selectedIndex--
                }
                event.accepted = true
            } else if (event.key === Qt.Key_Right) {
                if (selectedIndex < wallpapers.length - 1) {
                    selectedIndex++
                }
                event.accepted = true
            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                applyWallpaper()
                event.accepted = true
            }
        }

        // Slide and fade animation
        transform: Translate {
            y: wallpaperSelector._showAnimation ? 0 : 50

            Behavior on y {
                NumberAnimation {
                    duration: Settings.animationDurationMedium
                    easing.type: Settings.easingStandard
                }
            }
        }

        opacity: wallpaperSelector._showAnimation ? 1 : 0

        Behavior on opacity {
            NumberAnimation {
                duration: Settings.animationDurationMedium
                easing.type: Easing.OutQuad
            }
        }

        // Main card
        Card {
            anchors.fill: parent
            showBorder: true
            contentPadding: 16

            ColumnLayout {
                anchors.fill: parent
                spacing: 12

                // Title
                Text {
                    Layout.fillWidth: true
                    text: "Select Wallpaper"
                    color: Theme.textPrimary
                    font.pixelSize: Settings.fontSizeLarge
                    font.weight: Font.Bold
                    horizontalAlignment: Text.AlignHCenter
                }

                // Scrollable wallpaper grid
                ScrollView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true

                    ScrollBar.horizontal.policy: ScrollBar.AsNeeded
                    ScrollBar.vertical.policy: ScrollBar.AlwaysOff

                    // Horizontal row of thumbnails
                    Row {
                        spacing: thumbnailSpacing
                        padding: 8

                        Repeater {
                            model: wallpaperSelector.wallpapers

                            delegate: Item {
                                required property int index
                                required property var modelData

                                width: thumbnailSize
                                height: thumbnailSize

                                Rectangle {
                                    anchors.fill: parent
                                    color: Theme.cardBackground
                                    radius: Settings.cardRadius
                                    border.color: index === selectedIndex ? Theme.accent : Theme.borderDefault
                                    border.width: index === selectedIndex ? 3 : 1

                                    Behavior on border.color {
                                        ColorAnimation { duration: Settings.animationDurationShort }
                                    }

                                    Behavior on border.width {
                                        NumberAnimation { duration: Settings.animationDurationShort }
                                    }

                                    Image {
                                        anchors.fill: parent
                                        anchors.margins: 4
                                        source: "file://" + modelData.path
                                        fillMode: Image.PreserveAspectCrop
                                        smooth: true
                                        asynchronous: true
                                        cache: true

                                        layer.enabled: true
                                        layer.smooth: true
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            console.log("WallpaperSelector: Clicked thumbnail", index)
                                            if (index !== selectedIndex) {
                                                selectedIndex = index
                                            } else {
                                                applyWallpaper()
                                            }
                                        }
                                    }
                                }

                                // Wallpaper name below thumbnail
                                Text {
                                    anchors.top: parent.bottom
                                    anchors.topMargin: 4
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    width: parent.width
                                    text: modelData.name
                                    color: index === selectedIndex ? Theme.accent : Theme.textSecondary
                                    font.pixelSize: Settings.fontSizeSmall
                                    elide: Text.ElideMiddle
                                    horizontalAlignment: Text.AlignHCenter

                                    Behavior on color {
                                        ColorAnimation { duration: Settings.animationDurationShort }
                                    }
                                }
                            }
                        }

                        // Empty state
                        Text {
                            width: 400
                            height: thumbnailSize
                            text: "No wallpapers found in\n" + wallpapersDir
                            color: Theme.textSecondary
                            font.pixelSize: Settings.fontSizeMedium
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            visible: wallpaperSelector.wallpapers.length === 0
                        }
                    }
                }

                // Selected wallpaper info
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
}
