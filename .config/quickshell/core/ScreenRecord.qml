pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

/**
 * ScreenRecord - gpu-screen-recorder wrapper
 * Stop: SIGINT · Pause/Resume: SIGUSR2
 * Modes: screen | portal | region (slurp)
 */
QtObject {
    id: root

    property bool available: false
    property bool regionPickerAvailable: false
    property string binaryPath: ""
    property bool recording: false
    property bool pending: false // portal picker / region select in progress
    property bool paused: false
    property int elapsed: 0
    property int recorderPid: 0
    property string lastOutput: ""
    property string statusMessage: ""
    property string errorMessage: ""
    property string regionGeometry: "" // WxH+X+Y from slurp

    property bool includeAudio: true
    property bool includeMic: false
    property int fps: Settings.screenRecordFps
    // portal: always show picker (never restore previous session)
    property string captureMode: "screen" // screen | portal | region

    readonly property string recordingsDir: Settings.recordingsDir
    readonly property string elapsedText: formatElapsed(elapsed)
    readonly property string statusLabel: {
        if (!available)
            return "Not installed";
        if (pending && captureMode === "portal")
            return "Pick a source…";
        if (pending && captureMode === "region")
            return "Select a region…";
        if (paused)
            return "Paused";
        if (recording)
            return "Recording";
        return "Ready";
    }

    function formatElapsed(secs) {
        const s = Math.max(0, Math.floor(secs));
        const hours = Math.floor(s / 3600);
        const mins = Math.floor((s % 3600) / 60);
        const rem = (s % 60).toString().padStart(2, "0");
        if (hours > 0)
            return `${hours}:${mins.toString().padStart(2, "0")}:${rem}`;
        return `${mins}:${rem}`;
    }

    function outputPath() {
        const now = new Date();
        const pad = n => n.toString().padStart(2, "0");
        const stamp = `${now.getFullYear()}-${pad(now.getMonth() + 1)}-${pad(now.getDate())}_${pad(now.getHours())}-${pad(now.getMinutes())}-${pad(now.getSeconds())}`;
        return `${root.recordingsDir}/recording-${stamp}.mp4`;
    }

    function buildCommand(path) {
        const cmd = [
            root.binaryPath || "gpu-screen-recorder",
            "-f", String(root.fps),
            "-cursor", "yes",
            "-o", path
        ];

        if (root.captureMode === "portal") {
            cmd.push("-w", "portal");
            // Explicitly never restore — always show the portal picker
            cmd.push("-restore-portal-session", "no");
            // Drop any leftover restore token so the picker cannot be skipped
            Quickshell.execDetached(["rm", "-f", `${Quickshell.env("HOME")}/.config/gpu-screen-recorder/restore_token`]);
        } else if (root.captureMode === "region") {
            cmd.push("-w", "region");
            cmd.push("-region", root.regionGeometry);
        } else {
            cmd.push("-w", "screen");
        }

        if (root.includeAudio && root.includeMic)
            cmd.push("-a", "default_output|default_input");
        else if (root.includeAudio)
            cmd.push("-a", "default_output");
        else if (root.includeMic)
            cmd.push("-a", "default_input");

        return cmd;
    }

    function validPid() {
        const pid = Number(root.recorderPid || recorder.processId || 0);
        return pid > 1 ? Math.floor(pid) : 0;
    }

    function sendSignal(sigName) {
        const pid = root.validPid();
        if (pid > 1) {
            Quickshell.execDetached(["kill", `-${sigName}`, String(pid)]);
            return true;
        }
        Quickshell.execDetached(["pkill", `-SIG${sigName}`, "-x", "gpu-screen-recorder"]);
        return false;
    }

    function refreshAvailable() {
        if (availProc.running)
            availProc.running = false;
        availProc.running = true;
        if (slurpCheck.running)
            slurpCheck.running = false;
        slurpCheck.running = true;
    }

    function start() {
        if (!root.available) {
            root.refreshAvailable();
            root.errorMessage = "Install gpu-screen-recorder (pacman -S gpu-screen-recorder)";
            return;
        }
        if (root.recording || root.pending || recorder.running)
            return;

        if (root.captureMode === "region" && !root.regionPickerAvailable) {
            root.errorMessage = "Install slurp for region capture (pacman -S slurp)";
            return;
        }

        root.errorMessage = "";
        root.statusMessage = "";
        root.lastOutput = root.outputPath();
        root.regionGeometry = "";
        root.pending = true;
        root.paused = false;
        root.elapsed = 0;

        if (root.captureMode === "portal")
            root.statusMessage = "Pick a screen or window…";
        else if (root.captureMode === "region")
            root.statusMessage = "Drag to select a region…";

        ensureDir.command = ["mkdir", "-p", root.recordingsDir];
        ensureDir.running = true;
    }

    function stop() {
        if (!recorder.running && !root.recording && !root.pending)
            return;
        console.log("ScreenRecord: stop");
        // Cancel portal/region wait or stop active recording
        if (slurpProc.running) {
            slurpProc.running = false;
            root.pending = false;
            root.statusMessage = "Cancelled";
            return;
        }
        root.sendSignal("INT");
        root.statusMessage = root.lastOutput ? `Saving ${root.lastOutput}` : "Stopping…";
    }

    function togglePause() {
        if (!root.recording || root.pending)
            return;
        root.sendSignal("USR2");
        root.paused = !root.paused;
        root.statusMessage = root.paused ? "Paused" : "Recording…";
    }

    function toggle() {
        if (root.recording || root.pending)
            root.stop();
        else
            root.start();
    }

    function setCaptureMode(mode) {
        if (root.recording || root.pending)
            return;
        if (mode === "portal" || mode === "screen" || mode === "region")
            root.captureMode = mode;
    }

    function _launchRecorder() {
        recorder.command = root.buildCommand(root.lastOutput);
        recorder.running = true;
    }

    property var elapsedTimer: Timer {
        interval: 1000
        repeat: true
        running: root.recording && !root.paused && !root.pending
        onTriggered: root.elapsed++
    }

    property var pidCheckTimer: Timer {
        interval: 2000
        running: true
        repeat: true
        onTriggered: pidCheck.running = true
    }

    property var availProc: Process {
        command: [
            "sh", "-c",
            "for p in /usr/bin/gpu-screen-recorder /usr/sbin/gpu-screen-recorder; do " +
            "  if [ -x \"$p\" ]; then printf '%s' \"$p\"; exit 0; fi; " +
            "done; " +
            "command -v gpu-screen-recorder"
        ]
        running: false
        stdout: StdioCollector {
            id: availOut
        }
        onExited: code => {
            const path = availOut.text.trim();
            root.available = code === 0 && path.length > 0;
            root.binaryPath = root.available ? path : "";
            if (root.available) {
                if (root.errorMessage.indexOf("Install gpu-screen-recorder") === 0)
                    root.errorMessage = "";
            } else {
                console.warn("ScreenRecord: gpu-screen-recorder not found");
            }
        }
    }

    property var slurpCheck: Process {
        command: [
            "sh", "-c",
            "for p in /usr/bin/slurp /usr/sbin/slurp; do " +
            "  if [ -x \"$p\" ]; then exit 0; fi; " +
            "done; " +
            "command -v slurp >/dev/null"
        ]
        running: false
        onExited: code => {
            root.regionPickerAvailable = code === 0;
        }
    }

    property var ensureDir: Process {
        running: false
        onExited: code => {
            if (code !== 0) {
                root.pending = false;
                root.errorMessage = "Could not create recordings folder";
                return;
            }
            if (root.captureMode === "region") {
                slurpProc.command = ["/usr/bin/slurp", "-f", "%wx%h+%x+%y"];
                slurpProc.running = true;
                return;
            }
            root._launchRecorder();
        }
    }

    property var slurpProc: Process {
        running: false
        stdout: StdioCollector {
            id: slurpOut
        }
        onExited: code => {
            const geom = slurpOut.text.trim();
            if (code !== 0 || geom.length === 0) {
                root.pending = false;
                root.statusMessage = "Region select cancelled";
                root.errorMessage = "";
                return;
            }
            root.regionGeometry = geom;
            root.statusMessage = `Region ${geom}`;
            root._launchRecorder();
        }
    }

    property var recorder: Process {
        running: false

        stdout: StdioCollector {}

        stderr: SplitParser {
            onRead: data => {
                const line = data.trim();
                if (line.length === 0)
                    return;

                const lower = line.toLowerCase();

                // Portal/capture actually began encoding
                if (root.pending && (
                    lower.indexOf("update fps") >= 0
                    || lower.indexOf("new state: \"streaming\"") >= 0
                    || lower.indexOf("streaming") >= 0 && lower.indexOf("pipewire") >= 0
                )) {
                    root.pending = false;
                    root.recording = true;
                    root.elapsed = 0;
                    root.statusMessage = "Recording…";
                }

                if (line === "Unpaused" || line.endsWith("Unpaused")) {
                    root.paused = false;
                    root.statusMessage = "Recording…";
                } else if (line === "Paused" || line.endsWith("Paused")) {
                    root.paused = true;
                    root.statusMessage = "Paused";
                } else if (lower.indexOf("canceled") >= 0 || lower.indexOf("cancelled") >= 0
                           || lower.indexOf("selectsources failed") >= 0
                           || lower.indexOf("portal capture failed") >= 0) {
                    root.errorMessage = "Capture cancelled";
                    root.pending = false;
                } else if ((lower.indexOf("error") >= 0 && lower.indexOf("error: none") < 0)
                           || lower.indexOf("failed") >= 0) {
                    console.warn("ScreenRecord:", line);
                }
            }
        }

        onStarted: {
            root.recorderPid = Number(processId) || 0;
            root.paused = false;
            root.errorMessage = "";
            // Screen/region usually start immediately; portal waits for picker
            if (root.captureMode === "portal") {
                root.pending = true;
                root.recording = false;
                root.statusMessage = "Pick a screen or window…";
            } else {
                root.pending = false;
                root.recording = true;
                root.elapsed = 0;
                root.statusMessage = "Recording…";
            }
            console.log("ScreenRecord: started pid=", root.recorderPid, "mode=", root.captureMode);
        }

        onExited: code => {
            const wasPending = root.pending;
            root.recorderPid = 0;
            root.recording = false;
            root.pending = false;
            root.paused = false;
            if (code === 0) {
                root.statusMessage = root.lastOutput ? `Saved ${root.lastOutput}` : "Saved";
            } else if (wasPending) {
                root.statusMessage = "Cancelled";
                root.errorMessage = "";
            } else if (root.errorMessage.length === 0) {
                root.errorMessage = code === 127
                    ? "gpu-screen-recorder not found"
                    : `Recorder exited (${code})`;
            }
        }
    }

    property var pidCheck: Process {
        command: ["pidof", "gpu-screen-recorder"]
        running: false
        stdout: StdioCollector {
            id: pidOut
        }
        onExited: code => {
            const alive = code === 0;
            if (!alive && (root.recording || root.pending) && !recorder.running) {
                root.recording = false;
                root.pending = false;
                root.paused = false;
                root.recorderPid = 0;
            } else if (alive && !root.recording && !root.pending && !recorder.running) {
                const first = pidOut.text.trim().split(/\s+/)[0];
                const pid = Number(first) || 0;
                if (pid > 1) {
                    root.recorderPid = pid;
                    root.recording = true;
                }
            } else if (alive && root.recording && root.recorderPid <= 1) {
                const first = pidOut.text.trim().split(/\s+/)[0];
                const pid = Number(first) || 0;
                if (pid > 1)
                    root.recorderPid = pid;
            }
        }
    }

    Component.onCompleted: refreshAvailable()
}
