pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

/**
 * ScreenRecord - wf-recorder capture → ffmpeg VAAPI encode on the Intel iGPU.
 *
 * The monitors hang off the RX 580, whose VCE encoder hangs and resets the GPU
 * (ring vce0 timeout → VRAM lost). gpu-screen-recorder always encodes on the
 * monitor's GPU, so capture here (wf-recorder, raw frames over a pipe) and
 * encode with ffmpeg on Settings.screenRecordEncodeDevice instead.
 *
 * Stop: SIGINT to wf-recorder → ffmpeg sees EOF and finalises the file.
 * Modes: screen (focused output) | region (slurp). No pause (wf-recorder can't).
 */
QtObject {
    id: root

    property bool available: false
    property bool regionPickerAvailable: false
    property bool recording: false
    property bool pending: false // region select in progress
    readonly property bool paused: false
    readonly property bool canPause: false
    property int elapsed: 0
    property string lastOutput: ""
    property string statusMessage: ""
    property string errorMessage: ""
    property string regionGeometry: "" // "x,y WxH" from slurp

    property bool includeAudio: true
    property bool includeMic: false
    property int fps: Settings.screenRecordFps
    property string captureMode: "screen" // screen | region

    readonly property string recordingsDir: Settings.recordingsDir
    readonly property string elapsedText: formatElapsed(elapsed)
    readonly property string statusLabel: {
        if (!available)
            return "Not installed";
        if (pending)
            return "Select a region…";
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

    // sh -c script; values arrive as positional args, never spliced into the string.
    // $1 out file  $2 encode device  $3 fps  $4 wf-recorder target flag (-o/-g)
    // $5 target value  $6 audio mode: none|desktop|mic|both
    readonly property string _pipeline: `
        out="$1"; dev="$2"; fps="$3"; tflag="$4"; target="$5"; audio="$6"
        # No microphone connected (default source unresolved): drop the mic, keep recording
        case "$audio" in mic|both)
            src=$(pactl get-default-source 2>/dev/null)
            if [ -z "$src" ] || [ "$src" = "@DEFAULT_SOURCE@" ]; then
                [ "$audio" = both ] && audio=desktop || audio=none
            fi ;;
        esac
        case "$audio" in
            desktop) wfa="--audio=@DEFAULT_MONITOR@" ;;
            mic|both) wfa="--audio=@DEFAULT_SOURCE@" ;;
            *) wfa="" ;;
        esac
        # Desktop + mic: wf-recorder takes one device, so ffmpeg adds the monitor and mixes
        if [ "$audio" = both ]; then
            set -- -f pulse -i @DEFAULT_MONITOR@ -filter_complex "[0:a][1:a]amix=inputs=2:duration=first[a]" -map 0:v -map "[a]" -c:a aac -b:a 160k
        elif [ -n "$wfa" ]; then
            set -- -map 0 -c:a copy
        else
            set -- -map 0
        fi
        wf-recorder -y -r "$fps" "$tflag" "$target" $wfa -c rawvideo -m nut -f /dev/stdout \\
            | ffmpeg -hide_banner -loglevel error -y -vaapi_device "$dev" -f nut -i - "$@" \\
                -vf "hwupload,scale_vaapi=format=nv12" -c:v h264_vaapi -qp 24 "$out"
    `

    function buildCommand(path) {
        const audio = root.includeAudio && root.includeMic ? "both"
            : root.includeAudio ? "desktop"
            : root.includeMic ? "mic" : "none";
        const region = root.captureMode === "region";
        return ["sh", "-c", root._pipeline, "sh",
            path, Settings.screenRecordEncodeDevice, String(root.fps),
            region ? "-g" : "-o",
            region ? root.regionGeometry : Niri.focused_output_name,
            audio];
    }

    function refreshAvailable() {
        if (!availProc.running)
            availProc.running = true;
    }

    function start() {
        if (!root.available) {
            root.refreshAvailable();
            root.errorMessage = "Needs wf-recorder, ffmpeg and the iGPU encode device";
            return;
        }
        if (root.recording || root.pending || recorder.running)
            return;
        if (root.captureMode === "region" && !root.regionPickerAvailable) {
            root.errorMessage = "Install slurp for region capture (pacman -S slurp)";
            return;
        }

        root.errorMessage = "";
        root.statusMessage = root.captureMode === "region" ? "Drag to select a region…" : "";
        root.lastOutput = root.outputPath();
        root.regionGeometry = "";
        root.pending = root.captureMode === "region";
        root.elapsed = 0;

        ensureDir.command = ["mkdir", "-p", root.recordingsDir];
        ensureDir.running = true;
    }

    function stop() {
        if (slurpProc.running) {
            slurpProc.running = false;
            root.pending = false;
            root.statusMessage = "Cancelled";
            return;
        }
        if (!recorder.running)
            return;
        // Only our pipeline's wf-recorder (child of the sh we started)
        Quickshell.execDetached(["pkill", "-INT", "-P", String(recorder.processId), "-x", "wf-recorder"]);
        root.statusMessage = `Saving ${root.lastOutput}`;
    }

    function togglePause() {}

    function toggle() {
        if (root.recording || root.pending)
            root.stop();
        else
            root.start();
    }

    function setCaptureMode(mode) {
        if (root.recording || root.pending)
            return;
        if (mode === "screen" || mode === "region")
            root.captureMode = mode;
    }

    function _launchRecorder() {
        recorder.command = root.buildCommand(root.lastOutput);
        recorder.running = true;
    }

    property var elapsedTimer: Timer {
        interval: 1000
        repeat: true
        running: root.recording
        onTriggered: root.elapsed++
    }

    property var availProc: Process {
        command: ["sh", "-c", 'command -v wf-recorder >/dev/null && command -v ffmpeg >/dev/null && [ -e "$1" ]',
            "sh", Settings.screenRecordEncodeDevice]
        onExited: code => {
            root.available = code === 0;
            if (!root.available)
                console.warn("ScreenRecord: needs wf-recorder, ffmpeg and", Settings.screenRecordEncodeDevice);
        }
    }

    property var slurpCheck: Process {
        command: ["sh", "-c", "command -v slurp >/dev/null"]
        onExited: code => root.regionPickerAvailable = code === 0
    }

    property var ensureDir: Process {
        onExited: code => {
            if (code !== 0) {
                root.pending = false;
                root.errorMessage = "Could not create recordings folder";
                return;
            }
            if (root.captureMode === "region") {
                // slurp's default output is wf-recorder's -g format: "x,y WxH".
                // With a non-tty stdin slurp reads predefined boxes until EOF, and
                // Process keeps stdin open, so it would wait forever without drawing.
                slurpProc.command = ["sh", "-c", "exec slurp < /dev/null"];
                slurpProc.running = true;
                return;
            }
            root._launchRecorder();
        }
    }

    property var slurpProc: Process {
        stdout: StdioCollector {
            id: slurpOut
        }
        onExited: code => {
            const geom = slurpOut.text.trim();
            if (!root.pending)
                return; // cancelled via stop()
            if (code !== 0 || geom.length === 0) {
                root.pending = false;
                root.statusMessage = "Region select cancelled";
                return;
            }
            root.regionGeometry = geom;
            root._launchRecorder();
        }
    }

    property var recorder: Process {
        stderr: SplitParser {
            onRead: data => {
                const line = data.trim();
                // wf-recorder prints its stream setup; only surface real failures
                if (/error|failed|cannot|invalid/i.test(line))
                    console.warn("ScreenRecord:", line);
            }
        }

        onStarted: {
            root.pending = false;
            root.recording = true;
            root.elapsed = 0;
            root.statusMessage = "Recording…";
            console.log("ScreenRecord: started mode=", root.captureMode, "device=", Settings.screenRecordEncodeDevice);
        }

        onExited: code => {
            root.recording = false;
            root.pending = false;
            if (code === 0) {
                root.statusMessage = `Saved ${root.lastOutput}`;
            } else {
                root.errorMessage = `Recorder exited (${code})`;
                root.statusMessage = "";
            }
        }
    }

    Component.onCompleted: {
        availProc.running = true;
        slurpCheck.running = true;
    }
}
