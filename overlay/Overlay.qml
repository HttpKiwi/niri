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
    readonly property bool menuOpen: Ui.menuOn === output
    // full width while the menu is open or still shrinking back
    readonly property bool full: menuOpen || island.width > Tune.islandMaxWidth

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "grove:overlay"
    // A reserved strip: windows tile beside it, never under it. Only as wide as
    // what's drawn: the whole buffer repaints on every life tick, so a
    // full-screen overlay cost ~4% CPU for a few small lights.
    exclusionMode: ExclusionMode.Normal
    exclusiveZone: Tune.stripWidth
    anchors { top: true; bottom: true; left: true }
    // widens while the island shows a face; input still only lands on what's drawn
    implicitWidth: full ? (screen?.width ?? 1920) : island.wide ? Tune.islandMaxWidth : Tune.stripWidth
    WlrLayershell.keyboardFocus: menuOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    color: "transparent"

    mask: Region {
        item: root.menuOpen ? scrim : root.fullscreen ? null : lights
        Region { item: root.fullscreen && !root.menuOpen ? null : island }
    }

    // life clock for floating and breathing; stops when nothing is shown
    property real t: 0
    readonly property real startMs: Date.now()
    // smooth while the island moves; slow at rest
    readonly property bool busy: island.wide || menuOpen
    Timer {
        interval: Math.round(1000 / (root.busy ? Tune.busyFps : Tune.lifeFps))
        repeat: true
        running: !root.fullscreen && root.visible
        onTriggered: root.t = (Date.now() - root.startMs) / 1000
    }

    // Shade rising from the island's corner: the menu stands out, windows stay
    // visible behind it. (Compositor blur was dropped: niri blurred the whole
    // surface whenever the overlay widened, and xray hid the windows.)
    Item {
        id: scrim
        anchors.fill: parent
        opacity: root.menuOpen ? 1 : 0
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: 350; easing.type: Easing.OutCubic } }
        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: Qt.rgba(0.07, 0.10, 0.09, Tune.scrimOpacity + 0.45) }
                GradientStop { position: 0.4; color: Qt.rgba(0.07, 0.10, 0.09, Tune.scrimOpacity) }
                GradientStop { position: 0.85; color: Qt.rgba(0.07, 0.10, 0.09, 0) }
            }
        }
        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                GradientStop { position: 0.35; color: Qt.rgba(0.07, 0.10, 0.09, 0) }
                GradientStop { position: 1.0; color: Qt.rgba(0.07, 0.10, 0.09, 0.55) }
            }
        }
        TapHandler { onTapped: Ui.close() }
    }

    Item {
        anchors.fill: parent
        opacity: root.fullscreen && !root.menuOpen ? 0 : 1
        Behavior on opacity { NumberAnimation { duration: 400 } }

        // the clock that's always there: hours over minutes, top of the strip
        Column {
            x: 0
            y: 16
            width: Tune.stripWidth
            spacing: -2
            Repeater {
                model: [Qt.formatTime(Ambience.now, "HH"), Qt.formatTime(Ambience.now, "mm")]
                Text {
                    required property string modelData
                    required property int index
                    width: Tune.stripWidth
                    horizontalAlignment: Text.AlignHCenter
                    text: modelData
                    font.family: Tune.displayFont
                    font.pixelSize: 16
                    font.weight: index === 0 ? Font.DemiBold : Font.Normal
                    color: Ambience.phase === "night" ? Tune.ember : Tune.parch
                    opacity: index === 0 ? 0.95 : 0.7
                    style: Text.Outline
                    styleColor: Qt.rgba(0.05, 0.08, 0.07, 0.55)
                }
            }
        }

        Lights {
            id: lights
            output: root.output
            t: root.t
            // pinned to the strip: the overlay widens for faces and the menu
            width: Tune.stripWidth
            anchors.verticalCenter: parent.verticalCenter
        }

        Island {
            id: island
            t: root.t
            focusedScreen: Niri.focusedOutput === root.output
            menuOpen: root.menuOpen
            output: root.output
            moteTarget: Qt.point(lights.x + lights.nextMote.x - x, lights.y + lights.nextMote.y - y)
            // anchored at the seed's left edge; faces grow to the right
            x: (Tune.stripWidth - Tune.seedSize) / 2
            y: parent.height - height - Tune.seedMargin
        }
    }
}
