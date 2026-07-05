//@ pragma IconTheme Papirus
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.core
import qs.config

import qs.features.bar
import qs.features.background
import qs.features.decorations
import qs.features.lockscreen
import qs.features.notifications
import qs.features.wallpaper
import qs.features.dotmatrix

ShellRoot {
    Background {}
    UnifiedBar {}
    RoundedScreen {}
    LockScreen {}
    AutoLock {}

    IpcHandler {
        target: "appLauncher"

        function toggleLauncher() {
            const state = PanelStates.forName(Niri.focused_output_name);
            if (!state) return;
            // PanelState mutex closes wallpaper when launcher opens
            state.launcher = !state.launcher;
            if (!state.launcher)
                state.clipboard = false;
        }

        function toggleClipboard() {
            const state = PanelStates.forName(Niri.focused_output_name);
            if (!state) return;
            if (state.launcher && state.clipboard) {
                state.launcher = false;
                state.clipboard = false;
            } else {
                // Opening clipboard implies launcher; mutex closes wallpaper
                state.launcher = true;
                state.clipboard = true;
            }
        }
    }

    IpcHandler {
        target: "controlCenter"

        function toggleControlCenter() {
            const state = PanelStates.forName(Niri.focused_output_name);
            if (!state) return;
            state.historyPanel = !state.historyPanel;
        }
    }

    IpcHandler {
        target: "notificationHistory"

        function toggleHistory() {
            const state = PanelStates.forName(Niri.focused_output_name);
            if (!state) return;
            state.historyPanel = !state.historyPanel;
        }
    }

    IpcHandler {
        target: "wallpaperSelector"

        function toggleSelector() {
            const state = PanelStates.forName(Niri.focused_output_name);
            if (!state) return;
            // PanelState mutex closes launcher when wallpaper opens
            state.wallpaper = !state.wallpaper;
        }
    }

    NotificationManager {
        id: notificationManager
    }

    // Popups live in UnifiedBar (blob-mounted) so they share the bar input mask

    DotMatrixDemo {}

    IpcHandler {
        target: "storage"

        function clearAll() {
            Storage.clearAll()
        }
    }
}
