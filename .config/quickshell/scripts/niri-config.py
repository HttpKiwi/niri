#!/usr/bin/env python3
"""Safe get/set for a curated subset of niri config.kdl keys."""
from __future__ import annotations

import json
import re
import subprocess
import sys
from pathlib import Path

CONFIG = Path.home() / ".config" / "niri" / "config.kdl"
REPO = Path.home() / "niri" / ".config" / "niri" / "config.kdl"
if REPO.is_file():
    CONFIG = REPO


def read() -> str:
    return CONFIG.read_text(encoding="utf-8")


def write(text: str) -> None:
    CONFIG.write_text(text, encoding="utf-8")


def validate() -> tuple[bool, str]:
    try:
        p = subprocess.run(
            ["niri", "validate"],
            capture_output=True,
            text=True,
            timeout=10,
        )
        out = (p.stdout or "") + (p.stderr or "")
        return p.returncode == 0, out.strip()
    except Exception as e:
        return False, str(e)


def _block(text: str, name: str) -> tuple[int, int, str] | None:
    m = re.search(rf"(?m)^({re.escape(name)}\s*\{{)", text)
    if not m:
        return None
    start = m.start()
    i = m.end()
    depth = 1
    while i < len(text) and depth:
        if text[i] == "{":
            depth += 1
        elif text[i] == "}":
            depth -= 1
        i += 1
    return start, i, text[m.end() : i - 1]


def _replace_block(text: str, name: str, inner: str) -> str:
    b = _block(text, name)
    if not b:
        return text
    return text[: b[0]] + f"{name} {{{inner}}}" + text[b[1] :]


def _set_simple(inner: str, key: str, value: str) -> str:
    pat = re.compile(rf"(?m)^(\s*){re.escape(key)}\s+[^\n]*$")
    if pat.search(inner):
        return pat.sub(rf"\1{key} {value}", inner, count=1)
    return inner.rstrip() + f"\n    {key} {value}\n"


def _get_simple(inner: str, key: str) -> str | None:
    m = re.search(rf'(?m)^\s*{re.escape(key)}\s+"([^"]+)"', inner)
    if m:
        return m.group(1)
    m = re.search(rf"(?m)^\s*{re.escape(key)}\s+(\S+)", inner)
    return m.group(1) if m else None


def _flag_present(text: str, flag: str) -> bool:
    return bool(re.search(rf"(?m)^\s*{re.escape(flag)}\s*$", text))


def _set_toplevel_flag(text: str, flag: str, enabled: bool) -> str:
    if enabled:
        if _flag_present(text, flag):
            return text
        # insert near top after first comment block / before input
        m = re.search(r"(?m)^input\s*\{", text)
        line = f"{flag}\n\n"
        if m:
            return text[: m.start()] + line + text[m.start() :]
        return line + text
    return re.sub(rf"(?m)^\s*{re.escape(flag)}\s*\n?", "", text)


def _set_input_flag(text: str, flag: str, enabled: bool) -> str:
    b = _block(text, "input")
    if not b:
        return text
    inner = b[2]
    # remove existing active/commented
    inner = re.sub(rf"(?m)^\s*//\s*{re.escape(flag)}\s*$\n?", "", inner)
    inner = re.sub(rf"(?m)^\s*{re.escape(flag)}\s*$\n?", "", inner)
    if enabled:
        inner = inner.rstrip() + f"\n    {flag}\n"
    else:
        inner = inner.rstrip() + f"\n    // {flag}\n"
    return _replace_block(text, "input", inner)


def _hotkey_flag(text: str, flag: str) -> bool:
    b = _block(text, "hotkey-overlay")
    if not b:
        return False
    return bool(re.search(rf"(?m)^\s*{re.escape(flag)}\s*$", b[2]))


def _set_hotkey_flag(text: str, flag: str, enabled: bool) -> str:
    b = _block(text, "hotkey-overlay")
    if not b:
        if not enabled:
            return text
        block = f"hotkey-overlay {{\n  {flag}\n}}\n\n"
        m = re.search(r"(?m)^input\s*\{", text)
        if m:
            return text[: m.end()] + "\n\n" + block + text[m.end() :]
        return block + text
    inner = b[2]
    inner = re.sub(rf"(?m)^\s*//\s*{re.escape(flag)}\s*$\n?", "", inner)
    inner = re.sub(rf"(?m)^\s*{re.escape(flag)}\s*$\n?", "", inner)
    if enabled:
        inner = inner.rstrip() + f"\n  {flag}\n"
    return _replace_block(text, "hotkey-overlay", inner)


def _first_window_rule(text: str) -> tuple[int, int, str] | None:
    m = re.search(r"(?m)^(window-rule\s*\{)", text)
    if not m:
        return None
    start = m.start()
    i = m.end()
    depth = 1
    while i < len(text) and depth:
        if text[i] == "{":
            depth += 1
        elif text[i] == "}":
            depth -= 1
        i += 1
    return start, i, text[m.end() : i - 1]


def _inactive_opacity_rule(text: str) -> tuple[int, int, str] | None:
    for m in re.finditer(r"(?m)^window-rule\s*\{", text):
        start = m.start()
        i = m.end()
        depth = 1
        while i < len(text) and depth:
            if text[i] == "{":
                depth += 1
            elif text[i] == "}":
                depth -= 1
            i += 1
        block = text[m.end() : i - 1]
        if re.search(r"(?m)^\s*match is-active=false\b", block):
            return start, i, block
    return None


def _spring_params(inner: str, anim: str) -> tuple[float, int]:
    m = re.search(
        rf"(?ms){re.escape(anim)}\s*\{{[^}}]*spring\s+damping-ratio=([0-9.]+)\s+stiffness=(\d+)",
        inner,
    )
    if m:
        return float(m.group(1)), int(m.group(2))
    return 0.85, 800


def _set_spring(inner: str, anim: str, damping: float, stiffness: int) -> str:
    pat = re.compile(
        rf"(?ms)({re.escape(anim)}\s*\{{[^}}]*spring\s+)damping-ratio=[0-9.]+\s+stiffness=\d+"
    )
    repl = rf"\1damping-ratio={damping:.2f} stiffness={stiffness}"
    if pat.search(inner):
        return pat.sub(repl, inner, count=1)
    # insert animation block
    return (
        inner.rstrip()
        + f"\n\n    {anim} {{\n        spring damping-ratio={damping:.2f} stiffness={stiffness} epsilon=0.0001\n    }}\n"
    )


def get_values(text: str) -> dict:
    out: dict = {
        "gaps": 12,
        "blurPasses": 4,
        "blurNoise": 0.01,
        "blurSaturation": 1.2,
        "blurOffset": 1.8,
        "overviewZoom": 0.4,
        "cornerRadius": 18,
        "clipToGeometry": True,
        "inactiveOpacity": 0.90,
        "preferNoCsd": True,
        "centerFocusedColumn": "never",
        "focusRingWidth": 0,
        "focusFollowsMouse": True,
        "ffmMaxScroll": "80%",
        "warpMouseToFocus": False,
        "hotkeyOverlaySkip": True,
        "cursorSize": 24,
        "cursorTheme": "default",
        "animationsEnabled": True,
        "animationsSlowdown": 1.0,
        "workspaceSwitchDamping": 0.85,
        "workspaceSwitchStiffness": 800,
        "overviewAnimDamping": 0.8,
        "overviewAnimStiffness": 800,
        "path": str(CONFIG),
    }

    layout = _block(text, "layout")
    if layout:
        m = re.search(r"(?m)^\s*gaps\s+(\d+)", layout[2])
        if m:
            out["gaps"] = int(m.group(1))
        m = re.search(r'(?m)^\s*center-focused-column\s+"([^"]+)"', layout[2])
        if m:
            out["centerFocusedColumn"] = m.group(1)
        fr = _block("layout {\n" + layout[2] + "\n}", "focus-ring")
        # focus-ring is nested — parse from layout inner directly
        m = re.search(r"(?ms)focus-ring\s*\{[^}]*^\s*width\s+(\d+)", layout[2], re.M)
        if not m:
            m = re.search(r"(?m)focus-ring\s*\{[^}]*width\s+(\d+)", layout[2])
        if m:
            out["focusRingWidth"] = int(m.group(1))

    blur = _block(text, "blur")
    if blur:
        for key, dest, cast in (
            ("passes", "blurPasses", int),
            ("noise", "blurNoise", float),
            ("saturation", "blurSaturation", float),
            ("offset", "blurOffset", float),
        ):
            m = re.search(rf"(?m)^\s*{key}\s+([0-9.]+)", blur[2])
            if m:
                out[dest] = cast(m.group(1))

    overview = _block(text, "overview")
    if overview:
        m = re.search(r"(?m)^\s*zoom\s+([0-9.]+)", overview[2])
        if m:
            out["overviewZoom"] = float(m.group(1))

    wr = _first_window_rule(text)
    if wr:
        m = re.search(r"(?m)^\s*geometry-corner-radius\s+(\d+)", wr[2])
        if m:
            out["cornerRadius"] = int(m.group(1))
        out["clipToGeometry"] = bool(
            re.search(r"(?m)^\s*clip-to-geometry\s+true\b", wr[2])
        )

    inactive = _inactive_opacity_rule(text)
    if inactive:
        m = re.search(r"(?m)^\s*opacity\s+([0-9.]+)", inactive[2])
        if m:
            out["inactiveOpacity"] = float(m.group(1))

    out["preferNoCsd"] = _flag_present(text, "prefer-no-csd")

    # focus-follows-mouse
    active = re.search(r"(?m)^\s*focus-follows-mouse\b", text)
    commented = re.search(r"(?m)^\s*//\s*focus-follows-mouse\b", text)
    if active:
        out["focusFollowsMouse"] = True
        m = re.search(
            r'(?m)^\s*focus-follows-mouse\s+max-scroll-amount="([^"]+)"',
            text,
        )
        if m:
            out["ffmMaxScroll"] = m.group(1)
    elif commented:
        out["focusFollowsMouse"] = False
        m = re.search(
            r'(?m)^\s*//\s*focus-follows-mouse\s+max-scroll-amount="([^"]+)"',
            text,
        )
        if m:
            out["ffmMaxScroll"] = m.group(1)
    else:
        out["focusFollowsMouse"] = False

    out["warpMouseToFocus"] = bool(
        re.search(r"(?m)^\s*warp-mouse-to-focus\s*$", text)
    )
    out["hotkeyOverlaySkip"] = _hotkey_flag(text, "skip-at-startup")

    cursor = _block(text, "cursor")
    if cursor:
        theme = _get_simple(cursor[2], "xcursor-theme")
        if theme:
            out["cursorTheme"] = theme
        size = _get_simple(cursor[2], "xcursor-size")
        if size and size.isdigit():
            out["cursorSize"] = int(size)

    anim = _block(text, "animations")
    if anim:
        out["animationsEnabled"] = not bool(
            re.search(r"(?m)^\s*off\s*$", anim[2])
        )
        slow = _get_simple(anim[2], "slowdown")
        if slow:
            try:
                out["animationsSlowdown"] = float(slow)
            except ValueError:
                pass
        d, s = _spring_params(anim[2], "workspace-switch")
        out["workspaceSwitchDamping"] = d
        out["workspaceSwitchStiffness"] = s
        d, s = _spring_params(anim[2], "overview-open-close")
        out["overviewAnimDamping"] = d
        out["overviewAnimStiffness"] = s

    return out


def apply_values(text: str, patch: dict) -> str:
    if "gaps" in patch:
        b = _block(text, "layout")
        if b:
            inner = _set_simple(b[2], "gaps", str(int(patch["gaps"])))
            text = _replace_block(text, "layout", inner)

    if "centerFocusedColumn" in patch:
        b = _block(text, "layout")
        if b:
            val = str(patch["centerFocusedColumn"])
            if val not in ("never", "always", "on-overflow"):
                val = "never"
            inner = _set_simple(b[2], "center-focused-column", f'"{val}"')
            text = _replace_block(text, "layout", inner)

    if "focusRingWidth" in patch:
        b = _block(text, "layout")
        if b:
            width = int(patch["focusRingWidth"])
            inner = b[2]
            fr = re.search(r"(?ms)(focus-ring\s*\{)(.*?)(\})", inner)
            if fr:
                fr_inner = fr.group(2)
                if re.search(r"(?m)^\s*width\s+\d+", fr_inner):
                    fr_inner = re.sub(
                        r"(?m)^(\s*)width\s+\d+",
                        rf"\1width {width}",
                        fr_inner,
                        count=1,
                    )
                else:
                    fr_inner = fr_inner.rstrip() + f"\n      width {width}\n"
                inner = inner[: fr.start()] + fr.group(1) + fr_inner + fr.group(3) + inner[fr.end() :]
            else:
                inner = (
                    inner.rstrip()
                    + f"\n\n    focus-ring {{\n      width {width}\n    }}\n"
                )
            text = _replace_block(text, "layout", inner)

    blur_keys = {
        "blurPasses": ("passes", lambda v: str(int(v))),
        "blurNoise": ("noise", lambda v: str(float(v))),
        "blurSaturation": ("saturation", lambda v: str(float(v))),
        "blurOffset": ("offset", lambda v: str(float(v))),
    }
    if any(k in patch for k in blur_keys):
        b = _block(text, "blur")
        if b:
            inner = b[2]
            for pk, (ck, fmt) in blur_keys.items():
                if pk in patch:
                    inner = _set_simple(inner, ck, fmt(patch[pk]))
            text = _replace_block(text, "blur", inner)

    if "overviewZoom" in patch:
        b = _block(text, "overview")
        if b:
            inner = _set_simple(b[2], "zoom", str(float(patch["overviewZoom"])))
            text = _replace_block(text, "overview", inner)

    if "cornerRadius" in patch or "clipToGeometry" in patch:
        wr = _first_window_rule(text)
        if wr:
            inner = wr[2]
            if "cornerRadius" in patch:
                if re.search(r"(?m)^\s*geometry-corner-radius\s+\d+", inner):
                    inner = re.sub(
                        r"(?m)^(\s*)geometry-corner-radius\s+\d+",
                        rf"\1geometry-corner-radius {int(patch['cornerRadius'])}",
                        inner,
                        count=1,
                    )
                else:
                    inner = (
                        inner.rstrip()
                        + f"\n    geometry-corner-radius {int(patch['cornerRadius'])}\n"
                    )
            if "clipToGeometry" in patch:
                val = "true" if patch["clipToGeometry"] else "false"
                if re.search(r"(?m)^\s*clip-to-geometry\s+\w+", inner):
                    inner = re.sub(
                        r"(?m)^(\s*)clip-to-geometry\s+\w+",
                        rf"\1clip-to-geometry {val}",
                        inner,
                        count=1,
                    )
                else:
                    inner = inner.rstrip() + f"\n    clip-to-geometry {val}\n"
            text = text[: wr[0]] + "window-rule {" + inner + "}" + text[wr[1] :]

    if "inactiveOpacity" in patch:
        rule = _inactive_opacity_rule(text)
        opacity = f"{float(patch['inactiveOpacity']):.2f}"
        if rule:
            inner = rule[2]
            if re.search(r"(?m)^\s*opacity\s+[0-9.]+", inner):
                inner = re.sub(
                    r"(?m)^(\s*)opacity\s+[0-9.]+",
                    rf"\1opacity {opacity}",
                    inner,
                    count=1,
                )
            else:
                inner = inner.rstrip() + f"\n  opacity {opacity}\n"
            text = text[: rule[0]] + "window-rule {" + inner + "}" + text[rule[1] :]
        else:
            block = (
                "\nwindow-rule {\n"
                "  match is-active=false\n"
                f"  opacity {opacity}\n"
                "}\n"
            )
            wr = _first_window_rule(text)
            if wr:
                text = text[: wr[1]] + block + text[wr[1] :]
            else:
                text = text + block

    if "preferNoCsd" in patch:
        text = _set_toplevel_flag(text, "prefer-no-csd", bool(patch["preferNoCsd"]))

    if "warpMouseToFocus" in patch:
        text = _set_input_flag(text, "warp-mouse-to-focus", bool(patch["warpMouseToFocus"]))

    if "hotkeyOverlaySkip" in patch:
        text = _set_hotkey_flag(text, "skip-at-startup", bool(patch["hotkeyOverlaySkip"]))

    if "focusFollowsMouse" in patch or "ffmMaxScroll" in patch:
        scroll = patch.get("ffmMaxScroll", "80%")
        enabled = patch.get("focusFollowsMouse")
        cur = get_values(text)
        if enabled is None:
            enabled = cur["focusFollowsMouse"]
        if "ffmMaxScroll" not in patch:
            scroll = cur["ffmMaxScroll"]
        # normalize percent
        if isinstance(scroll, (int, float)):
            scroll = f"{int(scroll)}%"
        elif isinstance(scroll, str) and not scroll.endswith("%"):
            scroll = f"{scroll}%"

        line = (
            f'    focus-follows-mouse max-scroll-amount="{scroll}"'
            if enabled
            else f'    // focus-follows-mouse max-scroll-amount="{scroll}"'
        )
        text = re.sub(r"(?m)^\s*//\s*focus-follows-mouse[^\n]*\n?", "", text)
        text = re.sub(r"(?m)^\s*focus-follows-mouse[^\n]*\n?", "", text)
        b = _block(text, "input")
        if b:
            inner = b[2].rstrip() + "\n" + line + "\n"
            text = _replace_block(text, "input", inner)

    if "cursorSize" in patch or "cursorTheme" in patch:
        b = _block(text, "cursor")
        if b:
            inner = b[2]
            if "cursorTheme" in patch:
                theme = str(patch["cursorTheme"]).replace('"', "")
                inner = _set_simple(inner, "xcursor-theme", f'"{theme}"')
            if "cursorSize" in patch:
                inner = _set_simple(inner, "xcursor-size", str(int(patch["cursorSize"])))
            text = _replace_block(text, "cursor", inner)

    anim_patch_keys = (
        "animationsEnabled",
        "animationsSlowdown",
        "workspaceSwitchDamping",
        "workspaceSwitchStiffness",
        "overviewAnimDamping",
        "overviewAnimStiffness",
    )
    if any(k in patch for k in anim_patch_keys):
        b = _block(text, "animations")
        if b:
            inner = b[2]
            cur = get_values(text)
            if "animationsEnabled" in patch:
                enabled = bool(patch["animationsEnabled"])
                inner = re.sub(r"(?m)^\s*off\s*$\n?", "", inner)
                if not enabled:
                    inner = "\n    off\n" + inner.lstrip()
            if "animationsSlowdown" in patch:
                inner = _set_simple(
                    inner, "slowdown", f"{float(patch['animationsSlowdown']):.1f}"
                )
            d = float(patch.get("workspaceSwitchDamping", cur["workspaceSwitchDamping"]))
            s = int(patch.get("workspaceSwitchStiffness", cur["workspaceSwitchStiffness"]))
            if any(
                k in patch
                for k in ("workspaceSwitchDamping", "workspaceSwitchStiffness")
            ):
                inner = _set_spring(inner, "workspace-switch", d, s)
            d = float(patch.get("overviewAnimDamping", cur["overviewAnimDamping"]))
            s = int(patch.get("overviewAnimStiffness", cur["overviewAnimStiffness"]))
            if any(
                k in patch for k in ("overviewAnimDamping", "overviewAnimStiffness")
            ):
                inner = _set_spring(inner, "overview-open-close", d, s)
            text = _replace_block(text, "animations", inner)

    return text


def main() -> int:
    if len(sys.argv) < 2:
        print("usage: niri-config.py get|set '{json}'", file=sys.stderr)
        return 2
    cmd = sys.argv[1]
    text = read()
    if cmd == "get":
        print(json.dumps(get_values(text)))
        return 0
    if cmd == "set":
        patch = json.loads(sys.argv[2] if len(sys.argv) > 2 else "{}")
        new_text = apply_values(text, patch)
        write(new_text)
        ok, msg = validate()
        result = {"ok": ok, "message": msg, "values": get_values(read())}
        if not ok:
            write(text)
            result["restored"] = True
            result["values"] = get_values(text)
        print(json.dumps(result))
        return 0 if ok else 1
    print("unknown command", file=sys.stderr)
    return 2


if __name__ == "__main__":
    raise SystemExit(main())
