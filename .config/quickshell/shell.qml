//@ pragma IconTheme Papirus
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import qs.core

import qs.features.bar
import qs.features.background
import qs.features.decorations
import qs.features.notifications
import qs.features.osd
import qs.features.wallpaper

ShellRoot {
    Background {}
    UnifiedBar {}
    RoundedScreen {}
    VolumeOSD {}

    IpcHandler {
        target: "appLauncher"

        function toggleLauncher() {
            const state = PanelStates.forName(Niri.focused_output_name);
            if (!state) return;
            state.launcher = !state.launcher;
            state.clipboard = false;
        }

        function toggleClipboard() {
            const state = PanelStates.forName(Niri.focused_output_name);
            if (!state) return;
            if (state.launcher && state.clipboard) {
                state.launcher = false;
                state.clipboard = false;
            } else {
                state.launcher = true;
                state.clipboard = true;
            }
        }
    }

    NotificationManager {
        id: notificationManager
    }

    NotificationHistoryPanel {
        id: notificationHistoryPanel
    }

    WallpaperSelector {
        id: wallpaperSelector
    }
}
