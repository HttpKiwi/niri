pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import QtQuick

QtObject {
    id: root

    // Color properties that will be updated from JSON file
    property string background: "#191112"
    property string error: "#ffb4ab"
    property string error_container: "#93000a"
    property string inverse_on_surface: "#382e2f"
    property string inverse_primary: "#8e4956"
    property string inverse_surface: "#f0dee0"
    property string on_background: "#f0dee0"
    property string on_error: "#690005"
    property string on_error_container: "#ffdad6"
    property string on_primary: "#561d2a"
    property string on_primary_container: "#ffd9de"
    property string on_primary_fixed: "#3b0715"
    property string on_primary_fixed_variant: "#72333f"
    property string on_secondary: "#43292d"
    property string on_secondary_container: "#ffd9de"
    property string on_secondary_fixed: "#2c1519"
    property string on_secondary_fixed_variant: "#5c3f43"
    property string on_surface: "#f0dee0"
    property string on_surface_variant: "#d6c2c3"
    property string on_tertiary: "#452b08"
    property string on_tertiary_container: "#ffddba"
    property string on_tertiary_fixed: "#2b1700"
    property string on_tertiary_fixed_variant: "#5f411c"
    property string outline: "#9f8c8e"
    property string outline_variant: "#524345"
    property string primary: "#ffb2bd"
    property string primary_container: "#72333f"
    property string primary_fixed: "#ffd9de"
    property string primary_fixed_dim: "#ffb2bd"
    property string scrim: "#000000"
    property string secondary: "#e5bdc1"
    property string secondary_container: "#5c3f43"
    property string secondary_fixed: "#ffd9de"
    property string secondary_fixed_dim: "#e5bdc1"
    property string shadow: "#000000"
    property string source_color: "#db4d6f"
    property string surface: "#191112"
    property string surface_bright: "#413738"
    property string surface_container: "#261d1e"
    property string surface_container_high: "#312829"
    property string surface_container_highest: "#3c3233"
    property string surface_container_low: "#22191a"
    property string surface_container_lowest: "#140c0d"
    property string surface_dim: "#191112"
    property string surface_tint: "#ffb2bd"
    property string surface_variant: "#524345"
    property string tertiary: "#eabf90"
    property string tertiary_container: "#5f411c"
    property string tertiary_fixed: "#ffddba"
    property string tertiary_fixed_dim: "#eabf90"

    Component.onCompleted: {
        // Initial load
        console.log("Color: Component completed, loading initial colors")
        fileView.reload()
    }

    // FileView to read JSON file
    property QtObject fileView: FileView {
        id: fileView
        path: `${Quickshell.configDir}/common/Colors.json`
        watchChanges: true
        onFileChanged: {
            console.log("Color: File changed detected, reloading colors")
            reload()
        }
        onAdapterUpdated: {
            console.log("Color: Adapter updated, writing colors")
            writeAdapter()
        }

        JsonAdapter {
            id: adapter
            property string background
            property string error
            property string error_container
            property string inverse_on_surface
            property string inverse_primary
            property string inverse_surface
            property string on_background
            property string on_error
            property string on_error_container
            property string on_primary
            property string on_primary_container
            property string on_primary_fixed
            property string on_primary_fixed_variant
            property string on_secondary
            property string on_secondary_container
            property string on_secondary_fixed
            property string on_secondary_fixed_variant
            property string on_surface
            property string on_surface_variant
            property string on_tertiary
            property string on_tertiary_container
            property string on_tertiary_fixed
            property string on_tertiary_fixed_variant
            property string outline
            property string outline_variant
            property string primary
            property string primary_container
            property string primary_fixed
            property string primary_fixed_dim
            property string scrim
            property string secondary
            property string secondary_container
            property string secondary_fixed
            property string secondary_fixed_dim
            property string shadow
            property string source_color
            property string surface
            property string surface_bright
            property string surface_container
            property string surface_container_high
            property string surface_container_highest
            property string surface_container_low
            property string surface_container_lowest
            property string surface_dim
            property string surface_tint
            property string surface_variant
            property string tertiary
            property string tertiary_container
            property string tertiary_fixed
            property string tertiary_fixed_dim
            
            onBackgroundChanged: root.background = background
            onErrorChanged: root.error = error
            onError_containerChanged: root.error_container = error_container
            onInverse_on_surfaceChanged: root.inverse_on_surface = inverse_on_surface
            onInverse_primaryChanged: root.inverse_primary = inverse_primary
            onInverse_surfaceChanged: root.inverse_surface = inverse_surface
            onOn_backgroundChanged: root.on_background = on_background
            onOn_errorChanged: root.on_error = on_error
            onOn_error_containerChanged: root.on_error_container = on_error_container
            onOn_primaryChanged: root.on_primary = on_primary
            onOn_primary_containerChanged: root.on_primary_container = on_primary_container
            onOn_primary_fixedChanged: root.on_primary_fixed = on_primary_fixed
            onOn_primary_fixed_variantChanged: root.on_primary_fixed_variant = on_primary_fixed_variant
            onOn_secondaryChanged: root.on_secondary = on_secondary
            onOn_secondary_containerChanged: root.on_secondary_container = on_secondary_container
            onOn_secondary_fixedChanged: root.on_secondary_fixed = on_secondary_fixed
            onOn_secondary_fixed_variantChanged: root.on_secondary_fixed_variant = on_secondary_fixed_variant
            onOn_surfaceChanged: root.on_surface = on_surface
            onOn_surface_variantChanged: root.on_surface_variant = on_surface_variant
            onOn_tertiaryChanged: root.on_tertiary = on_tertiary
            onOn_tertiary_containerChanged: root.on_tertiary_container = on_tertiary_container
            onOn_tertiary_fixedChanged: root.on_tertiary_fixed = on_tertiary_fixed
            onOn_tertiary_fixed_variantChanged: root.on_tertiary_fixed_variant = on_tertiary_fixed_variant
            onOutlineChanged: root.outline = outline
            onOutline_variantChanged: root.outline_variant = outline_variant
            onPrimaryChanged: root.primary = primary
            onPrimary_containerChanged: root.primary_container = primary_container
            onPrimary_fixedChanged: root.primary_fixed = primary_fixed
            onPrimary_fixed_dimChanged: root.primary_fixed_dim = primary_fixed_dim
            onScrimChanged: root.scrim = scrim
            onSecondaryChanged: root.secondary = secondary
            onSecondary_containerChanged: root.secondary_container = secondary_container
            onSecondary_fixedChanged: root.secondary_fixed = secondary_fixed
            onSecondary_fixed_dimChanged: root.secondary_fixed_dim = secondary_fixed_dim
            onShadowChanged: root.shadow = shadow
            onSource_colorChanged: root.source_color = source_color
            onSurfaceChanged: root.surface = surface
            onSurface_brightChanged: root.surface_bright = surface_bright
            onSurface_containerChanged: root.surface_container = surface_container
            onSurface_container_highChanged: root.surface_container_high = surface_container_high
            onSurface_container_highestChanged: root.surface_container_highest = surface_container_highest
            onSurface_container_lowChanged: root.surface_container_low = surface_container_low
            onSurface_container_lowestChanged: root.surface_container_lowest = surface_container_lowest
            onSurface_dimChanged: root.surface_dim = surface_dim
            onSurface_tintChanged: root.surface_tint = surface_tint
            onSurface_variantChanged: root.surface_variant = surface_variant
            onTertiaryChanged: root.tertiary = tertiary
            onTertiary_containerChanged: root.tertiary_container = tertiary_container
            onTertiary_fixedChanged: root.tertiary_fixed = tertiary_fixed
            onTertiary_fixed_dimChanged: root.tertiary_fixed_dim = tertiary_fixed_dim
        }
    }
}