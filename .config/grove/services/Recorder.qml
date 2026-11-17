pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

/**
 * Recorder - wf-recorder capture piped to ffmpeg h264_vaapi on the Intel iGPU.
 *
 * Never encode on the RX 580: its VCE hangs and resets the GPU. wf-recorder
 * only captures (raw frames over a pipe); ffmpeg encodes on Tune.encodeDevice.
 * Stop = SIGINT to wf-recorder; ffmpeg sees EOF and finalises the file.
 * Ported from v1's ScreenRecord.qml without the settings plumbing.
 */
Singleton {
    id: root

    property bool recording: false
    property bool picking: false        // slurp region select in progress
    property int elapsed: 0
    property string lastFile: ""
    property string error: ""
    property string quality: "showcase" // showcase | clip

    readonly property var presets: ({
        showcase: { fps: Tune.recordFps, qp: 20, vf: "hwupload,scale_vaapi=format=nv12" },
        // short side 720, never upscaled
        clip: { fps: 30, qp: 26, vf: "hwupload,scale_vaapi=w='if(gt(iw,ih),-2,min(720,iw))':h='if(gt(iw,ih),min(720,ih),-2)':format=nv12" }
    })
    readonly property string elapsedText: {
        const s = elapsed, h = Math.floor(s / 3600), m = Math.floor(s % 3600 / 60), r = String(s % 60).padStart(2, "0");
        return h ? `${h}:${String(m).padStart(2, "0")}:${r}` : `${m}:${r}`;
    }

    // Values arrive as positional args, never spliced into the script.
    // $1 out  $2 encode device  $3 fps  $4 -o|-g  $5 output|geometry  $6 qp  $7 filter
    readonly property string _pipeline: `
        out="$1"; dev="$2"; fps="$3"; tflag="$4"; target="$5"; qp="$6"; vf="$7"
        mkdir -p "$(dirname "$out")"
        wf-recorder -y -r "$fps" "$tflag" "$target" --audio=@DEFAULT_MONITOR@ -c rawvideo -m nut -f /dev/stdout \\
            | ffmpeg -hide_banner -loglevel error -y -vaapi_device "$dev" -f nut -i - -map 0 -c:a copy \\
                -vf "$vf" -c:v h264_vaapi -qp "$qp" "$out"
    `

    function _stamp() {
        const d = new Date(), p = n => String(n).padStart(2, "0");
        return `${d.getFullYear()}-${p(d.getMonth() + 1)}-${p(d.getDate())}_${p(d.getHours())}-${p(d.getMinutes())}-${p(d.getSeconds())}`;
    }
    function _launch(flag, target) {
        const p = presets[quality] ?? presets.showcase;
        lastFile = `${Tune.recordingsDir}/recording-${_stamp()}.mp4`;
        proc.command = ["sh", "-c", _pipeline, "sh", lastFile, Tune.encodeDevice, String(p.fps), flag, target, String(p.qp), p.vf];
        proc.running = true;
    }

    function startScreen(output) {
        if (recording || picking || proc.running) return;
        error = "";
        _launch("-o", output);
    }
    function startRegion() {
        if (recording || picking || proc.running) return;
        error = "";
        picking = true;
        slurp.running = true;
    }
    function stop() {
        if (slurp.running) { slurp.running = false; picking = false; return; }
        if (proc.running)
            Quickshell.execDetached(["pkill", "-INT", "-P", String(proc.processId), "-x", "wf-recorder"]);
    }
    function toggle(output) { recording || picking ? stop() : startScreen(output); }

    Timer { interval: 1000; repeat: true; running: root.recording; onTriggered: root.elapsed++ }

    Process {
        id: slurp
        // non-tty stdin makes slurp wait for predefined boxes instead of drawing
        command: ["sh", "-c", "exec slurp < /dev/null"]
        stdout: StdioCollector { id: slurpOut }
        onExited: code => {
            const geom = slurpOut.text.trim();
            if (!root.picking) return;
            root.picking = false;
            if (code === 0 && geom) root._launch("-g", geom);
        }
    }

    Process {
        id: proc
        stderr: SplitParser {
            onRead: line => { if (/error|failed|cannot|invalid/i.test(line)) console.warn("Recorder:", line.trim()); }
        }
        onStarted: { root.recording = true; root.elapsed = 0; }
        onExited: code => {
            root.recording = false;
            if (code !== 0) root.error = `Recorder exited (${code})`;
        }
    }
}
