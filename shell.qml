pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.backdrop
import qs.overlay
import qs.services

/**
 * Grove - Quickshell v2. Two windows per screen: Backdrop (world) and,
 * from phase 2, Overlay (lights, island, menu). See PLAN.md.
 */
ShellRoot {
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

    IpcHandler {
        target: "ambience"

        // day | golden | night | auto
        function setPhase(phase: string): void { Ambience.forcedPhase = phase === "auto" ? "" : phase; }
        // clear | rain | auto
        function setWeather(weather: string): void { Ambience.forcedWeather = weather === "auto" ? "" : weather; }
        function get(): string { return Ambience.phase + " " + Ambience.weather; }
    }
}
