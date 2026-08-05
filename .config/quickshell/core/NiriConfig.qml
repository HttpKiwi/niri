pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

/**
 * NiriConfig - Curated get/set for niri config.kdl via scripts/niri-config.py
 */
QtObject {
    id: root

    readonly property string script: Quickshell.shellDir + "/scripts/niri-config.py"

    property int gaps: 12
    property int blurPasses: 4
    property real blurNoise: 0.01
    property real blurSaturation: 1.2
    property real blurOffset: 1.8
    property real overviewZoom: 0.4
    property int cornerRadius: 18
    property bool clipToGeometry: true
    property real inactiveOpacity: 0.9
    property bool preferNoCsd: true
    property string centerFocusedColumn: "never"
    property int focusRingWidth: 0
    property bool focusFollowsMouse: true
    property string ffmMaxScroll: "80%"
    property bool warpMouseToFocus: false
    property bool hotkeyOverlaySkip: true
    property int cursorSize: 24
    property string cursorTheme: "default"
    property bool animationsEnabled: true
    property real animationsSlowdown: 1.0
    property real workspaceSwitchDamping: 0.85
    property int workspaceSwitchStiffness: 800
    property real overviewAnimDamping: 0.8
    property int overviewAnimStiffness: 800
    property string configPath: ""
    property string statusMessage: ""
    property bool dirty: false
    property bool loading: false
    property var _pendingPatch: ({})

    readonly property int ffmMaxScrollPercent: {
        const m = String(ffmMaxScroll).match(/(\d+)/);
        return m ? Number(m[1]) : 80;
    }

    function refresh() {
        root.loading = true;
        getProc.running = true;
    }

    function apply(patch) {
        // Merge + debounce so live sliders don't spawn a validate/write per tick
        const next = Object.assign({}, root._pendingPatch, patch);
        root._pendingPatch = next;
        root.statusMessage = "Applying…";
        applyDebounce.restart();
    }

    function _flushApply() {
        const patch = root._pendingPatch;
        root._pendingPatch = ({});
        if (!patch || Object.keys(patch).length === 0)
            return;
        setProc.command = ["python3", root.script, "set", JSON.stringify(patch)];
        setProc.running = true;
    }

    function set(key, value) {
        root[key] = value;
        root.dirty = true;
        const patch = {};
        patch[key] = value;
        root.apply(patch);
    }

    function setGaps(v) { set("gaps", Math.round(v)); }
    function setBlurPasses(v) { set("blurPasses", Math.round(v)); }
    function setBlurNoise(v) { set("blurNoise", Math.round(v * 1000) / 1000); }
    function setBlurSaturation(v) { set("blurSaturation", Math.round(v * 100) / 100); }
    function setBlurOffset(v) { set("blurOffset", Math.round(v * 10) / 10); }
    function setOverviewZoom(v) { set("overviewZoom", Math.round(v * 100) / 100); }
    function setCornerRadius(v) { set("cornerRadius", Math.round(v)); }
    function setClipToGeometry(v) { set("clipToGeometry", !!v); }
    function setInactiveOpacity(v) { set("inactiveOpacity", Math.round(v * 100) / 100); }
    function setPreferNoCsd(v) { set("preferNoCsd", !!v); }
    function setCenterFocusedColumn(v) { set("centerFocusedColumn", v); }
    function setFocusRingWidth(v) { set("focusRingWidth", Math.round(v)); }
    function setFocusFollowsMouse(v) { set("focusFollowsMouse", !!v); }
    function setFfmMaxScrollPercent(v) { set("ffmMaxScroll", `${Math.round(v)}%`); }
    function setWarpMouseToFocus(v) { set("warpMouseToFocus", !!v); }
    function setHotkeyOverlaySkip(v) { set("hotkeyOverlaySkip", !!v); }
    function setCursorSize(v) { set("cursorSize", Math.round(v)); }
    function setAnimationsEnabled(v) { set("animationsEnabled", !!v); }
    function setAnimationsSlowdown(v) { set("animationsSlowdown", Math.round(v * 10) / 10); }
    function setWorkspaceSwitchDamping(v) { set("workspaceSwitchDamping", Math.round(v * 100) / 100); }
    function setWorkspaceSwitchStiffness(v) { set("workspaceSwitchStiffness", Math.round(v)); }
    function setOverviewAnimDamping(v) { set("overviewAnimDamping", Math.round(v * 100) / 100); }
    function setOverviewAnimStiffness(v) { set("overviewAnimStiffness", Math.round(v)); }

    function _ingest(obj) {
        if (!obj || typeof obj !== "object")
            return;
        const keys = [
            "gaps", "blurPasses", "blurNoise", "blurSaturation", "blurOffset",
            "overviewZoom", "cornerRadius", "clipToGeometry", "inactiveOpacity",
            "preferNoCsd", "centerFocusedColumn", "focusRingWidth",
            "focusFollowsMouse", "ffmMaxScroll", "warpMouseToFocus", "hotkeyOverlaySkip",
            "cursorSize", "cursorTheme", "animationsEnabled", "animationsSlowdown",
            "workspaceSwitchDamping", "workspaceSwitchStiffness",
            "overviewAnimDamping", "overviewAnimStiffness"
        ];
        for (let i = 0; i < keys.length; i++) {
            const k = keys[i];
            if (obj[k] !== undefined)
                root[k] = obj[k];
        }
        if (obj.path !== undefined)
            root.configPath = obj.path;
    }

    property var applyDebounce: Timer {
        interval: 220
        repeat: false
        onTriggered: root._flushApply()
    }

    property var getProc: Process {
        command: ["python3", root.script, "get"]
        running: false
        stdout: StdioCollector {
            id: getOut
        }
        onExited: code => {
            root.loading = false;
            if (code !== 0) {
                root.statusMessage = "Failed to read niri config";
                return;
            }
            try {
                root._ingest(JSON.parse(getOut.text.trim()));
                root.statusMessage = "";
                root.dirty = false;
            } catch (e) {
                root.statusMessage = "Parse error reading niri config";
            }
        }
    }

    property var setProc: Process {
        running: false
        stdout: StdioCollector {
            id: setOut
        }
        onExited: code => {
            try {
                const result = JSON.parse(setOut.text.trim());
                if (result.values)
                    root._ingest(result.values);
                if (result.ok) {
                    root.statusMessage = "Applied (niri will hot-reload)";
                    root.dirty = false;
                } else {
                    root.statusMessage = result.restored
                        ? `Invalid — restored. ${result.message || ""}`
                        : (result.message || "Apply failed");
                }
            } catch (e) {
                root.statusMessage = code === 0 ? "Applied" : "Apply failed";
            }
        }
    }

    Component.onCompleted: refresh()
}
