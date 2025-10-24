pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import qs.core
import "../../config"

/**
 * Background - Handles desktop background rendering
 * Supports both solid colors and image backgrounds
 *
 * Features:
 * - Color-based backgrounds
 * - Image-based backgrounds with scaling
 * - Multi-monitor support
 * - Dynamic configuration
 */

Scope {
    id: backgroundScope

    Variants {
        model: Quickshell.screens || []

        PanelWindow {
            property var modelData

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

            // Main background rectangle
            Rectangle {
                anchors.fill: parent

                // Use configured background color
                color: Settings.backgroundColor

                // Optional: Add image background if configured
                Image {
                    anchors.fill: parent
                    source: Settings.backgroundImagePath
                    fillMode: Image.PreserveAspectCrop
                    visible: Settings.backgroundType === "image" && Settings.backgroundImagePath !== ""
                    opacity: 1.0
                }
            }

            Component.onCompleted: {
                console.log("Background window created for screen:", modelData.name)
            }
        }
    }

    Component.onCompleted: {
        console.log("Background initialized")
        console.log("Background type:", Settings.backgroundType)
        console.log("Background color:", Settings.backgroundColor)
        if (Settings.backgroundType === "image") {
            console.log("Background image:", Settings.backgroundImagePath)
        }
    }
}
