pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

/**
 * HttpClient - Queued HTTP GET via curl for online shell features.
 * Callback signature: function(error, body) — error is null on success.
 */
Item {
    id: root

    visible: false

    readonly property int connectTimeoutSec: 5
    readonly property int maxTimeSec: 10

    property var _queue: []
    property bool _busy: false
    property var _activeCallback: null

    function shellQuote(value) {
        return "'" + String(value).replace(/'/g, "'\\''") + "'"
    }

    function get(url, callback, headers) {
        _queue.push({
            url: url,
            callback: callback,
            headers: headers || {}
        })
        _drain()
    }

    function _drain() {
        if (_busy || _queue.length === 0)
            return

        _busy = true
        var req = _queue.shift()
        _activeCallback = req.callback

        var headerArgs = ""
        var headerKeys = Object.keys(req.headers)
        for (var i = 0; i < headerKeys.length; i++) {
            var key = headerKeys[i]
            headerArgs += " -H " + shellQuote(key + ": " + req.headers[key])
        }

        var cmd = "/usr/bin/curl -sS --fail --connect-timeout "
            + connectTimeoutSec + " --max-time " + maxTimeSec
            + " --compressed" + headerArgs + " " + shellQuote(req.url)

        requestProc._stdoutText = ""
        requestProc._stderrText = ""
        requestProc.command = ["sh", "-c", cmd]
        requestProc.running = true
    }

    function _finish(success, body, errorText) {
        var cb = _activeCallback
        _activeCallback = null
        _busy = false

        if (cb) {
            if (success)
                cb(null, body)
            else
                cb(errorText || "Request failed", null)
        }

        _drain()
    }

    Process {
        id: requestProc
        running: false

        property string _stdoutText: ""
        property string _stderrText: ""

        stdout: StdioCollector {
            onStreamFinished: requestProc._stdoutText = text
        }

        stderr: StdioCollector {
            onStreamFinished: requestProc._stderrText = text
        }

        onExited: (exitCode, exitStatus) => {
            var ok = exitCode === 0
            var errText = requestProc._stderrText.trim()
            if (!ok && !errText)
                errText = "HTTP request failed (exit " + exitCode + ")"
            root._finish(ok, requestProc._stdoutText, errText)
        }
    }
}
