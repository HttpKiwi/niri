pragma ComponentBehavior: Bound

import QtQuick
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
            property string currentPath: Settings.backgroundImagePath
            property string previousPath: ""
            property real oldLayerX: 0
            property real newLayerX: 0
            property bool isTransitioning: false
            property real transitionScreenWidth: 1920

            onCurrentPathChanged: {
                if (previousPath === "") {
                    previousPath = currentPath
                    oldLayerX = 0
                    newLayerX = 0
                    return
                }

                if (currentPath !== previousPath && !isTransitioning) {
                    isTransitioning = true
                    const direction = Settings.wallpaperChangeDirection
                    transitionScreenWidth = modelData ? modelData.width : 1920
                    
                    if (direction > 0) {
                        oldLayerX = 0
                        newLayerX = transitionScreenWidth
                    } else {
                        oldLayerX = 0
                        newLayerX = -transitionScreenWidth
                    }
                }
            }

            Behavior on oldLayerX {
                NumberAnimation {
                    duration: 350
                    easing.type: Easing.OutQuad
                }
            }

            Behavior on newLayerX {
                NumberAnimation {
                    duration: 350
                    easing.type: Easing.OutQuad
                }
            }

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

            // Solid Color Background (fallback) - base layer
            Rectangle {
                anchors.fill: parent
                color: Settings.backgroundColor
                visible: !hasImage || detectedType === "unknown"
            }

            // Previous wallpaper layer (sliding out)
            Item {
                anchors.fill: parent
                transform: Translate {
                    x: oldLayerX
                }
                visible: isTransitioning && previousPath !== ""

                Image {
                    anchors.fill: parent
                    source: previousPath
                    fillMode: Image.PreserveAspectCrop
                    opacity: 1.0
                    asynchronous: true
                    cache: false

                    visible: hasImage && bgUtil.getBackgroundType(previousPath) === "image"
                }

                AnimatedImage {
                    anchors.fill: parent
                    source: previousPath
                    fillMode: Image.PreserveAspectCrop
                    opacity: 1.0
                    playing: true
                    paused: false
                    cache: false

                    visible: hasImage && bgUtil.getBackgroundType(previousPath) === "animated"
                }
            }

            // New wallpaper layer (sliding in)
            Item {
                anchors.fill: parent
                transform: Translate {
                    x: newLayerX
                }

                Image {
                    anchors.fill: parent
                    source: currentPath
                    fillMode: Image.PreserveAspectCrop
                    opacity: 1.0
                    asynchronous: true
                    cache: false

                    visible: hasImage && detectedType === "image"

                    onStatusChanged: {
                        if (status === Image.Ready) {
                            console.log("Background: New image loaded, completing slide")
                            Qt.callLater(() => {
                                oldLayerX = Settings.wallpaperChangeDirection > 0 ? -transitionScreenWidth : transitionScreenWidth
                                newLayerX = 0
                                previousPath = currentPath
                                isTransitioning = false
                            })
                        }
                    }
                }

                AnimatedImage {
                    anchors.fill: parent
                    source: currentPath
                    fillMode: Image.PreserveAspectCrop
                    opacity: 1.0
                    playing: true
                    paused: false
                    cache: false

                    visible: hasImage && detectedType === "animated"

                    onStatusChanged: {
                        if (status === Image.Ready) {
                            console.log("Background: New animated image loaded, completing slide")
                            Qt.callLater(() => {
                                oldLayerX = Settings.wallpaperChangeDirection > 0 ? -transitionScreenWidth : transitionScreenWidth
                                newLayerX = 0
                                previousPath = currentPath
                                isTransitioning = false
                            })
                        }
                    }

                    onSourceChanged: {
                        playing = false
                        currentFrame = 0
                        playing = true
                    }
                }
            }

            Component.onCompleted: {
                console.log("Background window created for screen:", modelData.name)
                previousPath = Settings.backgroundImagePath
                oldLayerX = 0
                newLayerX = 0
            }
        }
    }

    Component.onCompleted: {
        console.log("Background initialized")
    }
}
