pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.services

/**
 * Frame - the screen's black rim, alive: four click-through edge strips draw
 * one drifting rounded rectangle (shaders/frame.frag). Only ~14px strips
 * repaint, slowly; hidden under fullscreen windows.
 */
Scope {
    id: root

    required property var screen
    readonly property string output: screen?.name ?? ""
    readonly property bool fullscreen: Niri.fullscreenOn(output, screen?.width ?? 0, screen?.height ?? 0)
    readonly property int thick: Tune.frameRadius + 4

    property real t: 0
    readonly property real startMs: Date.now()
    Timer {
        interval: Math.round(1000 / Tune.frameFps)
        repeat: true
        running: !root.fullscreen
        onTriggered: root.t = (Date.now() - root.startMs) / 1000
    }

    Variants {
        model: ["top", "bottom", "left", "right"]

        PanelWindow {
            id: win
            required property string modelData
            readonly property bool horizontal: modelData === "top" || modelData === "bottom"
            readonly property real sw: root.screen.width
            readonly property real sh: root.screen.height

            screen: root.screen
            visible: !root.fullscreen
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "grove:frame"
            exclusionMode: ExclusionMode.Ignore
            color: "transparent"
            mask: Region {}
            anchors {
                top: modelData !== "bottom"
                bottom: modelData !== "top"
                left: modelData !== "right"
                right: modelData !== "left"
            }
            // left/right strips sit between the top and bottom ones
            margins {
                top: horizontal ? 0 : root.thick
                bottom: horizontal ? 0 : root.thick
            }
            implicitWidth: horizontal ? 0 : root.thick
            implicitHeight: horizontal ? root.thick : 0

            ShaderEffect {
                anchors.fill: parent
                blending: true
                property vector2d screenSize: Qt.vector2d(win.sw, win.sh)
                property vector2d origin: Qt.vector2d(
                    win.modelData === "right" ? win.sw - root.thick : 0,
                    win.modelData === "bottom" ? win.sh - root.thick : win.modelData === "top" ? 0 : root.thick)
                property vector2d stripSize: Qt.vector2d(width, height)
                property real radius: Tune.frameRadius
                property real inset: Tune.frameInset
                property real amp: Tune.frameAmp
                property real t: root.t
                fragmentShader: Qt.resolvedUrl("../shaders/frame.frag.qsb")
            }
        }
    }
}
