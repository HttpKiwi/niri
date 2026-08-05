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

ShellRoot {
    Background {}
    UnifiedBar {}
    RoundedScreen {}
    LockScreen {}
    AutoLock {}

    IpcHandler {
        target: "settings"

        function toggle() {
            const state = PanelStates.forName(Niri.focused_output_name);
            if (!state) return;
            state.settings = !state.settings;
        }

        function open() {
            const state = PanelStates.forName(Niri.focused_output_name);
            if (!state) return;
            state.settings = true;
        }

        function close() {
            const state = PanelStates.forName(Niri.focused_output_name);
            if (!state) return;
            state.settings = false;
        }

        function isOpen(): bool {
            const state = PanelStates.forName(Niri.focused_output_name);
            return !!(state && state.settings);
        }
    }

    IpcHandler {
        target: "appLauncher"

        function toggleLauncher() {
            const state = PanelStates.forName(Niri.focused_output_name);
            if (!state) return;
            if (state.launcher) {
                state.launcher = false;
            } else {
                // Always open on Apps — clear stale clipboard flag from Super+V / tab switch
                state.clipboard = false;
                state.launcher = true;
            }
        }

        function toggleClipboard() {
            const state = PanelStates.forName(Niri.focused_output_name);
            if (!state) return;
            if (state.launcher && state.clipboard) {
                state.launcher = false;
            } else {
                // Opening clipboard implies launcher; mutex closes wallpaper
                state.clipboard = true;
                state.launcher = true;
            }
        }
    }

    IpcHandler {
        target: "controlCenter"

        function toggleControlCenter() {
            const state = PanelStates.forName(Niri.focused_output_name);
            if (!state) return;
            state.controlCenter = !state.controlCenter;
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

    IpcHandler {
        target: "audio"

        function raiseVolume() {
            Audio.raiseVolume();
        }

        function lowerVolume() {
            Audio.lowerVolume();
        }

        function toggleMute() {
            Audio.toggleMute();
        }

        function toggleMicMute() {
            Audio.toggleMicMute();
        }
    }

    IpcHandler {
        target: "screenrecord"

        function toggle() {
            ScreenRecord.toggle();
        }

        function start() {
            ScreenRecord.start();
        }

        function stop() {
            ScreenRecord.stop();
        }

        function pause() {
            ScreenRecord.togglePause();
        }

        function isRecording(): bool {
            return ScreenRecord.recording;
        }
    }

    NotificationManager {
        id: notificationManager
    }

    // Popups live in UnifiedBar (blob-mounted) so they share the bar input mask

    IpcHandler {
        target: "storage"

        function clearAll() {
            Storage.clearAll()
        }
    }

    IpcHandler {
        target: "notifications"

        function dismissFocused() {
            NotificationKeyboard.dismissFocusedPopup()
        }

        function focusPopup() {
            NotificationKeyboard.focusPopup()
        }

        function navigateUp() {
            NotificationKeyboard.navigatePopup(-1)
        }

        function navigateDown() {
            NotificationKeyboard.navigatePopup(1)
        }

        function activateFocused() {
            NotificationKeyboard.activateFocusedPopup()
        }
    }

    Connections {
        target: NotificationModel.model
        function onCountChanged() {
            NotificationKeyboard.onPopupCountChanged()
        }
    }
}
