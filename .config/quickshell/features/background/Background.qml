pragma ComponentBehavior: Bound

import QtQuick
import QtMultimedia
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import qs.core
import "../../config"
import "."

Scope {
    id: backgroundScope

    BackgroundUtil {
        id: bgUtil
    }

    Variants {
        model: Quickshell.screens || []

        PanelWindow {
            property var modelData
            property string detectedType: bgUtil.getBackgroundType(Settings.backgroundImagePath)
            property bool hasImage: Settings.backgroundImagePath !== ""

            visible: true
            screen: modelData || Quickshell.screens[0]
            exclusionMode: ExclusionMode.Ignore
            exclusiveZone: 0
            WlrLayershell.namespace: "overview"
            WlrLayershell.layer: WlrLayer.Background
            color: "transparent"

            anchors {
                top: true
                left: true
                right: true
                bottom: true
            }

            property bool useLayer1: true
            property string _pendingWallpaper: ""
            property string _currentWallpaper: Settings.backgroundImagePath

            Timer {
                id: clearPendingTimer
                interval: 350
                onTriggered: {
                    _pendingWallpaper = ""
                }
            }

            Item {
                anchors.fill: parent

                // Layer 1 (active layer)
                Item {
                    id: layer1
                    anchors.fill: parent
                    opacity: 1.0
                    Behavior on opacity { NumberAnimation { duration: 300; easing.type: Easing.InOutQuad } }

                    // Solid color (fallback)
                    Rectangle {
                        anchors.fill: parent
                        color: Settings.backgroundColor
                        visible: !_currentWallpaper || detectedType === "unknown"
                    }

                    // Static Image
                    Image {
                        id: image1
                        anchors.fill: parent
                        source: _currentWallpaper
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        cache: true
                        visible: hasImage && detectedType === "image"
                    }

                    // Animated Image (GIF, WebP, APNG)
                    AnimatedImage {
                        id: animImage1
                        anchors.fill: parent
                        source: _currentWallpaper
                        fillMode: Image.PreserveAspectCrop
                        playing: true
                        cache: false
                        visible: hasImage && detectedType === "animated"
                    }

                    // Video
                    MediaPlayer {
                        id: videoPlayer1
                        source: _currentWallpaper
                        loops: MediaPlayer.Infinite
                        autoPlay: true
                        videoOutput: videoOutput1
                        audioOutput: null
                    }

                    VideoOutput {
                        id: videoOutput1
                        anchors.fill: parent
                        fillMode: VideoOutput.PreserveAspectCrop
                        visible: hasImage && detectedType === "video"
                    }
                }

                // Layer 2 (for crossfade transition)
                Item {
                    id: layer2
                    anchors.fill: parent
                    opacity: 0.0
                    Behavior on opacity { NumberAnimation { duration: 300; easing.type: Easing.InOutQuad } }

                    // Solid color (fallback)
                    Rectangle {
                        anchors.fill: parent
                        color: Settings.backgroundColor
                        visible: !_pendingWallpaper
                    }

                    // Static Image
                    Image {
                        anchors.fill: parent
                        source: _pendingWallpaper
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        cache: true
                        visible: _pendingWallpaper && bgUtil.getBackgroundType(_pendingWallpaper) === "image"
                    }

                    // Animated Image (GIF, WebP, APNG)
                    AnimatedImage {
                        anchors.fill: parent
                        source: _pendingWallpaper
                        fillMode: Image.PreserveAspectCrop
                        playing: true
                        cache: false
                        visible: _pendingWallpaper && bgUtil.getBackgroundType(_pendingWallpaper) === "animated"
                    }

                    // Video
                    MediaPlayer {
                        id: videoPlayer2
                        source: _pendingWallpaper
                        loops: MediaPlayer.Infinite
                        autoPlay: true
                        videoOutput: videoOutput2
                        audioOutput: null
                    }

                    VideoOutput {
                        id: videoOutput2
                        anchors.fill: parent
                        fillMode: VideoOutput.PreserveAspectCrop
                        visible: _pendingWallpaper && bgUtil.getBackgroundType(_pendingWallpaper) === "video"
                    }
                }
            }

            Connections {
                target: Settings
                function onBackgroundImagePathChanged() {
                    if (Settings.backgroundImagePath !== _currentWallpaper && Settings.backgroundImagePath !== "") {
                        var newWallpaper = Settings.backgroundImagePath
                        var newType = bgUtil.getBackgroundType(newWallpaper)
                        console.log("Background: Switching to", newWallpaper, "type:", newType)

                        _pendingWallpaper = newWallpaper
                        clearPendingTimer.stop()

                        if (useLayer1) {
                            layer2.opacity = 1
                            layer1.opacity = 0
                        } else {
                            layer1.opacity = 1
                            layer2.opacity = 0
                        }
                        useLayer1 = !useLayer1
                        _currentWallpaper = newWallpaper

                        clearPendingTimer.start()
                    }
                }
            }

            Component.onCompleted: {
                console.log("Background window created for screen:", modelData.name)
                console.log("Background type:", detectedType)
            }
        }
    }

    Component.onCompleted: {
        console.log("Background initialized")
    }
}
