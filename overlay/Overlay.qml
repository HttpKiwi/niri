import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.services

/**
 * Overlay - the top layer, one per screen: workspace lights on the left edge
 * and the island in the bottom-left corner. Input only lands on what's drawn;
 * everything else passes through to windows. Hidden while a window is fullscreen.
 * At rest it's a strip along the left edge; the island widens it in phases 3–4.
 */
PanelWindow {
    id: root

    readonly property string output: screen?.name ?? ""
    readonly property bool fullscreen: Niri.fullscreenOn(output, screen?.width ?? 0, screen?.height ?? 0)

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "grove:overlay"
    exclusionMode: ExclusionMode.Ignore
    // Only as wide as what's drawn: the whole buffer repaints on every life tick,
    // so a full-screen overlay cost ~4% CPU for a few small lights.
    anchors { top: true; bottom: true; left: true }
    implicitWidth: Tune.overlayRestWidth
    color: "transparent"

    mask: Region {
        item: root.fullscreen ? null : lights
        Region { item: root.fullscreen ? null : island }
    }

    // life clock for floating and breathing; stops when nothing is shown
    property real t: 0
    readonly property real startMs: Date.now()
    Timer {
        interval: Math.round(1000 / Tune.lifeFps)
        repeat: true
        running: !root.fullscreen && root.visible
        onTriggered: root.t = (Date.now() - root.startMs) / 1000
    }

    Item {
        anchors.fill: parent
        opacity: root.fullscreen ? 0 : 1
        Behavior on opacity { NumberAnimation { duration: 400 } }

        Lights {
            id: lights
            output: root.output
            t: root.t
            x: 2
            anchors.verticalCenter: parent.verticalCenter
        }

        Island {
            id: island
            t: root.t
            x: Tune.seedMargin
            y: parent.height - height - Tune.seedMargin
        }
    }
}
