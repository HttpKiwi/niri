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

            // Solid Color Background (fallback)
            Rectangle {
                anchors.fill: parent
                color: Settings.backgroundColor
                visible: !hasImage || detectedType === "unknown"
            }

            // Static Image
            Image {
                anchors.fill: parent
                source: Settings.backgroundImagePath
                fillMode: Image.PreserveAspectCrop
                opacity: 1.0
                asynchronous: true
                cache: true

                visible: hasImage && detectedType === "image"

                onStatusChanged: {
                    if (status === Image.Ready) {
                        console.log("Background: Static image loaded")
                    } else if (status === Image.Error) {
                        console.error("Background: Failed to load image:", errorString)
                    }
                }
            }

            // Animated Image (GIF, WebP, APNG)
            AnimatedImage {
                anchors.fill: parent
                source: Settings.backgroundImagePath
                fillMode: Image.PreserveAspectCrop
                opacity: 1.0
                playing: true
                paused: false
                cache: true

                visible: hasImage && detectedType === "animated"

                onSourceChanged: {
                    console.log("Background: Animated image source changed")
                }

                onCurrentFrameChanged: {
                    if (currentFrame === frameCount - 1) {
                        currentFrame = 0
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
