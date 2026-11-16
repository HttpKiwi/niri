pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.backdrop
import qs.lock
import qs.overlay
import qs.services

/**
 * Grove - Quickshell v2. Two windows per screen: Backdrop (world) and,
 * from phase 2, Overlay (lights, island, menu). See PLAN.md.
 */
ShellRoot {
    Lock { id: lock }

    Variants {
        model: Quickshell.screens
        Backdrop {
            required property var modelData
            screen: modelData
        }
    }
    Variants {
        model: Quickshell.screens
        Overlay {
            required property var modelData
            screen: modelData
        }
    }

    IpcHandler {
        target: "grove"

        function ping(): string { return "grove"; }
        function reload(): void { Quickshell.reload(true); }
    }

    // Same targets and functions as v1, so `grove ipc` keybinds work on either shell
    IpcHandler {
        target: "audio"

        function raiseVolume(): void { Audio.raiseVolume(); }
        function lowerVolume(): void { Audio.lowerVolume(); }
        function toggleMute(): void { Audio.toggleMute(); }
        function toggleMicMute(): void { Audio.toggleMicMute(); }
    }

    IpcHandler {
        target: "screenrecord"

        function toggle(): void { Recorder.toggle(Niri.focusedOutput); }
        function start(): void { Recorder.startScreen(Niri.focusedOutput); }
        function startRegion(): void { Recorder.startRegion(); }
        function stop(): void { Recorder.stop(); }
        // showcase | clip
        function setQuality(q: string): void { if (Recorder.presets[q] && !Recorder.recording) Recorder.quality = q; }
        function isRecording(): bool { return Recorder.recording; }
    }

    // v1's names, so Super+Space / Super+V work on either shell through `grove ipc`
    IpcHandler {
        target: "appLauncher"

        function toggleLauncher(): void { Ui.toggle(Niri.focusedOutput, "all"); }
        function toggleClipboard(): void { Ui.toggle(Niri.focusedOutput, "clipboard"); }
    }

    IpcHandler {
        target: "menu"

        // all | apps | windows | tools | phone | clipboard | inbox | system
        function open(section: string): void { Ui.open(Niri.focusedOutput, section); }
        function toggle(section: string): void { Ui.toggle(Niri.focusedOutput, section); }
        function close(): void { Ui.close(); }
    }

    IpcHandler {
        target: "notifications"

        function markRead(): void { Notifs.markRead(); }
        function unread(): int { return Notifs.unread; }
    }

    IpcHandler {
        target: "ambience"

        // day | golden | night | auto
        function setPhase(phase: string): void { Ambience.forcedPhase = phase === "auto" ? "" : phase; }
        // clear | rain | auto
        function setWeather(weather: string): void { Ambience.forcedWeather = weather === "auto" ? "" : weather; }
        function get(): string { return Ambience.phase + " " + Ambience.weather + " sun " + Ambience.sun.rise.toFixed(2) + "-" + Ambience.sun.set.toFixed(2); }
    }

    IpcHandler {
        target: "lock"

        function lockSession(): void { lock.lockNow(); }
        function isLocked(): bool { return lock.locked; }
    }
}

