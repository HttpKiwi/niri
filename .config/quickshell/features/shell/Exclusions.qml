pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.config

Scope {
    id: root

    required property ShellScreen screen

    ExclusionWin { anchors.left: true; exclusiveZone: root.bt }
    ExclusionWin { anchors.top: true; exclusiveZone: root.bt }
    ExclusionWin { anchors.right: true; exclusiveZone: root.bt }
    ExclusionWin { anchors.bottom: true; exclusiveZone: root.bt }

    readonly property real bt: Settings.screenBorderWidth

    component ExclusionWin: PanelWindow {
        screen: root.screen
        color: "transparent"
        WlrLayershell.namespace: "quickshell:border-exclusion"
        exclusiveZone: root.bt
        mask: Region {}
        implicitWidth: 1
        implicitHeight: 1
    }
}
