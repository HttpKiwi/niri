pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.services

/**
 * Frame - the screen's rounded black corners: four small click-through windows
 * drawn once by shaders/frame.frag (it can also drift: pass amp > 0 and tick t).
 * Hidden under fullscreen windows.
 */
Scope {
    id: root

    required property var screen
    readonly property string output: screen?.name ?? ""
    readonly property bool fullscreen: Niri.fullscreenOn(output, screen?.width ?? 0, screen?.height ?? 0)
    readonly property int size: Tune.frameRadius + 2

    Variants {
        model: ["tl", "tr", "bl", "br"]

        PanelWindow {
            id: win
            required property string modelData
            readonly property bool right: modelData[1] === "r"
            readonly property bool bottom: modelData[0] === "b"

            screen: root.screen
            visible: !root.fullscreen
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "grove:frame"
            exclusionMode: ExclusionMode.Ignore
            color: "transparent"
            mask: Region {}
            anchors { top: !bottom; bottom: bottom; left: !right; right: right }
            implicitWidth: root.size
            implicitHeight: root.size

            ShaderEffect {
                anchors.fill: parent
                blending: true
                property vector2d screenSize: Qt.vector2d(root.screen.width, root.screen.height)
                property vector2d origin: Qt.vector2d(win.right ? root.screen.width - root.size : 0,
                                                       win.bottom ? root.screen.height - root.size : 0)
                property vector2d stripSize: Qt.vector2d(width, height)
                property real radius: Tune.frameRadius
                property real inset: 0
                property real amp: 0
                property real t: 0
                fragmentShader: Qt.resolvedUrl("../shaders/frame.frag.qsb")
            }
        }
    }
}

