pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import qs.core
import qs.config
import qs.features.decorations

/**
 * BackgroundShadow - Screen border shadow matching the bar and screen border styling
 * Mimics the design of the screen border with rounded corners and subtle shadow
 * Matches bar and screen border styling. Overview hiding disabled.
 */

Scope {
    id: shadowScope

    Variants {
        model: Quickshell.screens || []

        PanelWindow {
            property var modelData

            visible: !!modelData
            screen: modelData
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

            // Top gradient shadow (inward)
            Rectangle {
              anchors.topMargin: 30
              anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                height: 10
                gradient: Gradient {
                    GradientStop { position: 0.0; color: Qt.rgba(0, 0, 0, 1) }
                    GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0) }
                }
            }

            // Bottom gradient shadow (inward)
            Rectangle {
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                height: 10
                gradient: Gradient {
                    GradientStop { position: 0.0; color: Qt.rgba(0, 0, 0, 0) }
                    GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 1) }
                }
            }

            // Left gradient shadow (inward)
            Rectangle {
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.bottom: parent.bottom
                width: 10
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: Qt.rgba(0, 0, 0, 1) }
                    GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0) }
                }
            }

            // Right gradient shadow (inward)
            Rectangle {
                anchors.top: parent.top
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                width: 10
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: Qt.rgba(0, 0, 0, 0) }
                    GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 1) }
                }
            }

            Component.onCompleted: {
                console.log("Background shadow created for screen:", modelData.name)
                console.log("Shadow visibility: always when modelData (overview hiding disabled)")
            }
        }
    }

    Component.onCompleted: {
        console.log("Background shadow initialized")
    }
}
