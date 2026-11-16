import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.services

/**
 * Warmth - the eye comfort filter: one click-through amber veil over each
 * screen, above everything. Drawn once (nothing repaints). Niri has no gamma
 * control, so this lifts the blacks a little instead of shifting the white
 * point; keep it faint.
 */
PanelWindow {
    id: root

    readonly property bool on: Store.prefs.eye === true

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "grove:warmth"
    exclusionMode: ExclusionMode.Ignore
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    mask: Region {}
    visible: veil.opacity > 0

    Rectangle {
        id: veil
        anchors.fill: parent
        color: Tune.eyeTint
        opacity: root.on ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 700; easing.type: Easing.InOutQuad } }
    }
}
