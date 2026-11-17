#!/usr/bin/env python3
"""Push Millennium's quick.css into the running Steam through its CEF debug port.

Millennium only watches quick.css while its own editor is open, so a changed file
reaches Steam at the next start. This sets the <style id="MillenniumQuickCss"> tag
of every open Steam window instead. Needs ~/.steam/steam/.cef-enable-remote-debugging
(Steam then listens on 127.0.0.1:8080). Quietly does nothing when Steam isn't there.
Usage: steam-push-css.py [quick.css] [port]
"""
import base64, json, os, socket, struct, sys, urllib.request

css_path = sys.argv[1] if len(sys.argv) > 1 else os.path.expanduser("~/.config/millennium/quick.css")
port = int(sys.argv[2]) if len(sys.argv) > 2 else 8080
css = open(css_path, encoding="utf8").read()
expr = ("(()=>{const s=document.getElementById('MillenniumQuickCss');"
        "if(s){s.innerHTML=%s;return 1}return 0})()" % json.dumps(css))


def evaluate(ws_url, expression):
    host, _, path = ws_url[len("ws://"):].partition("/")
    h, _, p = host.partition(":")
    s = socket.create_connection((h, int(p or 80)), timeout=3)
    key = base64.b64encode(os.urandom(16)).decode()
    s.sendall(("GET /%s HTTP/1.1\r\nHost: %s\r\nUpgrade: websocket\r\nConnection: Upgrade\r\n"
               "Sec-WebSocket-Key: %s\r\nSec-WebSocket-Version: 13\r\n\r\n" % (path, host, key)).encode())
    buf = b""
    while b"\r\n\r\n" not in buf:
        chunk = s.recv(4096)
        if not chunk:
            return None
        buf += chunk
    payload = json.dumps({"id": 1, "method": "Runtime.evaluate", "params": {"expression": expression}}).encode()
    mask = os.urandom(4)
    n = len(payload)
    head = bytes([0x81]) + (bytes([0x80 | n]) if n < 126 else bytes([0x80 | 126]) + struct.pack(">H", n)
                            if n < 65536 else bytes([0x80 | 127]) + struct.pack(">Q", n))
    s.sendall(head + mask + bytes(b ^ mask[i % 4] for i, b in enumerate(payload)))
    try:
        s.recv(65536)      # the reply; its content doesn't matter
    except OSError:
        pass
    s.close()


try:
    targets = json.load(urllib.request.urlopen("http://127.0.0.1:%d/json" % port, timeout=2))
except OSError:
    sys.exit(0)
hit = 0
for t in targets:
    if t.get("type") == "page" and t.get("webSocketDebuggerUrl"):
        try:
            evaluate(t["webSocketDebuggerUrl"], expr)
            hit += 1
        except OSError:
            pass
print("steam-push-css: %d windows" % hit)
