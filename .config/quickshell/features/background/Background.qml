pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import qs.core
import "../../config"

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
            WlrLayershell.namespace: "overview"
            WlrLayershell.layer: WlrLayer.Background
            color: "transparent"

            anchors {
                top: true
                left: true
                right: true
                bottom: true
            }

            Image {
                id: backgroundImage
                anchors.fill: parent
                source: Settings.backgroundImagePath
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                cache: true
            }

            Rectangle {
                anchors.fill: parent
                color: Settings.backgroundColor
                visible: !Settings.backgroundImagePath
            }
        }
    }

    Component.onCompleted: {
        console.log("Background initialized")
    }
}
