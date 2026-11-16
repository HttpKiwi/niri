pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

/**
 * Status - what the status lights show: CPU and RAM use (0..1) and the
 * headset's battery (headsetcontrol; -1 when it's off or absent).
 */
Singleton {
    id: root

    property real cpu: 0
    property real ram: 0
    property int battery: -1
    property var _prev: null

    Timer {
        interval: Tune.statusPoll
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: { stat.reload(); mem.reload(); }
    }
    FileView {
        id: stat
        path: "/proc/stat"
        onLoaded: {
            const m = text().match(/^cpu\s+(.*)$/m);
            if (!m) return;
            const v = m[1].trim().split(/\s+/).map(Number);
            const total = v.reduce((a, b) => a + b, 0), idle = v[3] + (v[4] ?? 0);
            if (root._prev && total > root._prev.total)
                root.cpu = 1 - (idle - root._prev.idle) / (total - root._prev.total);
            root._prev = { total, idle };
        }
    }
    FileView {
        id: mem
        path: "/proc/meminfo"
        onLoaded: {
            const t = text();
            const total = Number(t.match(/MemTotal:\s*(\d+)/)?.[1] ?? 0);
            const avail = Number(t.match(/MemAvailable:\s*(\d+)/)?.[1] ?? 0);
            if (total) root.ram = 1 - avail / total;
        }
    }

    Timer {
        interval: Tune.batteryPoll
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: if (!hs.running) hs.running = true
    }
    Process {
        id: hs
        command: ["headsetcontrol", "-b"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lvl = text.match(/Level:\s*(\d+)%/);
                root.battery = lvl && /BATTERY_AVAILABLE/.test(text) ? parseInt(lvl[1]) : -1;
            }
        }
    }
}
