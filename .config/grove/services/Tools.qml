pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

/**
 * Tools - the one-shot helpers behind the menu: qalc, clipboard history,
 * OCR, QR, colour picking, the phone. Every command gets its values as
 * positional args, never spliced into a shell string.
 */
Singleton {
    id: root

    // ---- calculator / units (qalc) ----
    property string calcQuery: ""
    property string calcAnswer: ""
    // Only things that look like maths or a conversion: qalc reads plain words as units
    function looksLikeCalc(q) {
        const s = q.trim();
        return /\d/.test(s) && (/[+\-*/^%()]/.test(s) || /\s(to|in)\s/i.test(s) || /^=/.test(s));
    }
    function calc(q) {
        calcQuery = q;
        if (!looksLikeCalc(q)) { calcAnswer = ""; return; }
        calcDebounce.restart();
    }
    Timer {
        id: calcDebounce
        interval: 120
        onTriggered: {
            qalc.running = false;
            qalc.command = ["qalc", "-t", root.calcQuery.replace(/^=/, "")];
            qalc.running = true;
        }
    }
    Process {
        id: qalc
        stdout: StdioCollector {
            onStreamFinished: {
                const a = text.trim();
                // qalc echoes unparsable input back or returns nothing useful
                root.calcAnswer = a && a !== root.calcQuery.trim() ? a : "";
            }
        }
    }

    // ---- clipboard history (cliphist) ----
    property var clips: []     // { id, preview }
    function loadClips() { cliplist.running = true; }
    function pasteClip(id) {
        Quickshell.execDetached(["sh", "-c", 'cliphist decode "$1" | wl-copy', "sh", String(id)]);
    }
    Process {
        id: cliplist
        command: ["cliphist", "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.clips = text.split("\n").filter(l => l).slice(0, Tune.clipMax).map(l => {
                    const tab = l.indexOf("\t");
                    return { id: l.slice(0, tab), preview: l.slice(tab + 1) };
                });
            }
        }
    }

    // types into whichever window gets focus back once the menu closes
    function type(text) { Quickshell.execDetached(["sh", "-c", 'sleep 0.18; wtype -- "$1"', "sh", text]); }
    function copy(text) { Quickshell.execDetached(["wl-copy", "--", text]); }
    function notify(summary, body) { Quickshell.execDetached(["notify-send", "-a", "Grove", summary, body ?? ""]); }

    // ---- screen tools: run after the menu has closed so it isn't in the shot ----
    readonly property string _ocr: `
        g=$(slurp < /dev/null) || exit 0
        t=$(grim -g "$g" - | tesseract stdin stdout -l eng+spa 2>/dev/null | sed -e 's/[[:space:]]*$//')
        [ -z "$t" ] && { notify-send -a Grove "No text found"; exit 0; }
        printf '%s' "$t" | wl-copy
        notify-send -a Grove "Text copied" "$(printf '%s' "$t" | head -c 160)"
    `
    readonly property string _qrScan: `
        g=$(slurp < /dev/null) || exit 0
        t=$(grim -g "$g" - | zbarimg --raw -q - 2>/dev/null | head -n 1)
        [ -z "$t" ] && { notify-send -a Grove "No QR code found"; exit 0; }
        case "$t" in
            http://*|https://*) xdg-open "$t"; notify-send -a Grove "Opened link" "$t" ;;
            *) printf '%s' "$t" | wl-copy; notify-send -a Grove "QR copied" "$t" ;;
        esac
    `
    readonly property string _pick: `
        h=$(niri msg pick-color | sed -n 's/^Hex: *//p')
        [ -z "$h" ] && exit 0
        printf '%s' "$h" | wl-copy
        notify-send -a Grove "Colour copied" "$h"
    `
    function ocr() { Quickshell.execDetached(["sh", "-c", "sleep 0.35; " + _ocr]); }
    function qrScan() { Quickshell.execDetached(["sh", "-c", "sleep 0.35; " + _qrScan]); }
    function pickColor() { Quickshell.execDetached(["sh", "-c", "sleep 0.35; " + _pick]); }

    // Clipboard as a QR code: written to a file the menu shows big
    readonly property string qrFile: Quickshell.env("XDG_RUNTIME_DIR") + "/grove-qr.png"
    property int qrVersion: 0
    signal qrReady()
    function qrFromClipboard() { qrMake.running = true; }
    Process {
        id: qrMake
        command: ["sh", "-c", 'wl-paste --no-newline | head -c 2000 | qrencode -s 12 -m 2 -o "$1"', "sh", root.qrFile]
        onExited: code => {
            if (code === 0) { root.qrVersion++; root.qrReady(); }
            else root.notify("Couldn't make a QR code", "The clipboard is empty or too long");
        }
    }

    // ---- phone (NectarLink; Grove's patched build adds mirror and open-app) ----
    function phone(task) { Quickshell.execDetached(["nectarlink-desktop", "--task", task]); }
    property var phoneApps: []
    function loadPhoneApps() { phoneAppsProc.running = true; }
    Process {
        id: phoneAppsProc
        command: ["sh", "-c", 'f=$(ls "$1"/cache/apps/*.json 2>/dev/null | head -n 1); [ -n "$f" ] && cat "$f"', "sh", Tune.nectarlinkData]
        stdout: StdioCollector {
            onStreamFinished: {
                try { root.phoneApps = JSON.parse(text); } catch (e) { root.phoneApps = []; }
            }
        }
    }
    function phoneIcon(pkg) {
        return "file://" + Tune.nectarlinkData + "/cache/icons/" + pkg.replace(/[^A-Za-z0-9._]/g, "_") + ".png";
    }

    // an image source for a notification's icon: its own, else the app's desktop entry
    function iconUrl(icon, app) {
        if (icon) return icon.startsWith("/") ? "file://" + icon : icon.startsWith("file:") ? icon : "image://icon/" + icon;
        const e = app ? DesktopEntries.heuristicLookup(app) : null;
        return e?.icon ? "image://icon/" + e.icon : "";
    }
}
