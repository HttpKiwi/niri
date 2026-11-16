import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.services

/**
 * Backdrop - the world layer (one per screen): wallpaper now; clock, grade
 * and life land here in phase 1. Never takes input.
 */
PanelWindow {
    id: root

    WlrLayershell.layer: WlrLayer.Background
    WlrLayershell.namespace: "grove:backdrop"
    exclusionMode: ExclusionMode.Ignore
    anchors { top: true; bottom: true; left: true; right: true }
    color: "#111a17"
    mask: Region {}

    Image {
        anchors.fill: parent
        source: Wallpaper.path ? "file://" + Wallpaper.path : ""
        // Cover with sourceSize only; a clip rect makes Qt ignore sourceSize (v1 bug)
        fillMode: Image.PreserveAspectCrop
        sourceSize: Qt.size(root.width, root.height)
        asynchronous: true
        retainWhileLoading: true
        // The texture is all we need; the pixmap cache would keep a CPU copy per screen
        cache: false
    }
}
