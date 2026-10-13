pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import QtQuick

/**
 * Color - Matugen palette from common/Colors.json (written by matugen-cache.sh).
 * Read-only: only the keys Theme uses; defaults apply until the file loads.
 */
QtObject {
    id: root

    readonly property string error: adapter.error || "#ffb4ab"
    readonly property string on_error: adapter.on_error || "#690005"
    readonly property string on_primary: adapter.on_primary || "#561d2a"
    readonly property string on_primary_container: adapter.on_primary_container || "#ffd9de"
    readonly property string on_surface: adapter.on_surface || "#f0dee0"
    readonly property string on_surface_variant: adapter.on_surface_variant || "#d6c2c3"
    readonly property string outline: adapter.outline || "#9f8c8e"
    readonly property string outline_variant: adapter.outline_variant || "#524345"
    readonly property string primary: adapter.primary || "#ffb2bd"
    readonly property string primary_container: adapter.primary_container || "#72333f"
    readonly property string secondary: adapter.secondary || "#e5bdc1"
    readonly property string secondary_container: adapter.secondary_container || "#5c3f43"
    readonly property string surface: adapter.surface || "#191112"
    readonly property string surface_container_high: adapter.surface_container_high || "#312829"
    readonly property string surface_container_highest: adapter.surface_container_highest || "#3c3233"
    readonly property string tertiary: adapter.tertiary || "#eabf90"

    property QtObject fileView: FileView {
        path: `${Quickshell.shellDir}/common/Colors.json`
        watchChanges: true
        onFileChanged: reload()

        JsonAdapter {
            id: adapter
            property string error
            property string on_error
            property string on_primary
            property string on_primary_container
            property string on_surface
            property string on_surface_variant
            property string outline
            property string outline_variant
            property string primary
            property string primary_container
            property string secondary
            property string secondary_container
            property string surface
            property string surface_container_high
            property string surface_container_highest
            property string tertiary
        }
    }
}
