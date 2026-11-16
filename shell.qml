pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.backdrop

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

    IpcHandler {
        target: "grove"

        function ping(): string { return "grove"; }
        function reload(): void { Quickshell.reload(true); }
    }
}
