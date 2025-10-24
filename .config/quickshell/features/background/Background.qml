pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import qs.core
import "../../config"
import "."

/**
 * Background - Handles desktop background rendering
 * Supports solid colors, static images, and animated images
 *
 * Features:
 * - Color-based backgrounds
 * - Static image backgrounds with scaling
 * - Animated image backgrounds (GIF, WebP, APNG)
 * - Multi-monitor support
 * - Automatic format detection
 */

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
            WlrLayershell.namespace: "quickshell:background"
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
            Loader {
                anchors.fill: parent
                active: hasImage && detectedType === "image"
                sourceComponent: Image {
                    anchors.fill: parent
                    source: Settings.backgroundImagePath
                    fillMode: Image.PreserveAspectCrop
                    opacity: 1.0

                    onStatusChanged: {
                        if (status === Image.Ready) {
                            console.log("Loaded static image background:", Settings.backgroundImagePath)
                        } else if (status === Image.Error) {
                            console.error("Failed to load static image:", errorString)
                        }
                    }
                }
            }

            // Animated Image (GIF, WebP, APNG)
            Loader {
                anchors.fill: parent
                active: hasImage && detectedType === "animated"
                sourceComponent: AnimatedImage {
                    anchors.fill: parent
                    source: Settings.backgroundImagePath
                    fillMode: Image.PreserveAspectCrop
                    opacity: 1.0
                    playing: true
                    paused: false
                    cache: true

                    onStatusChanged: {
                        if (status === Image.Ready) {
                            console.log("Loaded animated background:", Settings.backgroundImagePath)
                            console.log("Frame count:", frameCount, "Current frame:", currentFrame)
                        } else if (status === Image.Error) {
                            console.error("Failed to load animated background:", errorString)
                        }
                    }
                }
            }

            Component.onCompleted: {
                console.log("Background window created for screen:", modelData.name)
                console.log("Detected background type:", detectedType)
                console.log("File path:", Settings.backgroundImagePath)
                console.log("MIME type:", bgUtil.getMimeType(Settings.backgroundImagePath))
            }
        }
    }

    Component.onCompleted: {
        console.log("Background initialized")
        console.log("Background image path:", Settings.backgroundImagePath)
        console.log("Auto-detected type:", bgUtil.getBackgroundType(Settings.backgroundImagePath))
        console.log("Is animated:", bgUtil.isAnimated(Settings.backgroundImagePath))
        console.log("Is video:", bgUtil.isVideo(Settings.backgroundImagePath))
    }
}
