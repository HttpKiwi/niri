#!/usr/bin/env python3

import json
import subprocess

workspace_list = []
active_workspace_id = None
window_title = None
window_map = {}
is_overview = False

def write_status():
    with open("/tmp/niri_status.json", "w") as f:
        json.dump({
            "title": window_title,
            "workspaces": workspace_list,
            "active_workspace": active_workspace_id,
            "is_overview": is_overview,
            "focused_workspace_idx": focused_workspace_idx
        }, f)

with subprocess.Popen(
    ["niri", "msg", "--json", "event-stream"],
    stdout=subprocess.PIPE,
    text=True,
    bufsize=1,
) as proc:
    for line in proc.stdout:
        try:
            event = json.loads(line)

            if "WorkspacesChanged" in event:
                raw = event["WorkspacesChanged"]["workspaces"]

                # Clean and sort
                workspace_list = sorted(
                [
                    {
                        "id": ws["id"],
                        "idx": ws["idx"],
                        "name": ws["name"],
                        "is_active": ws["is_active"],
                        "is_focused": ws["is_focused"]
                    }
                    for ws in raw
                ],
                key=lambda ws: ws.get("idx", 0)
                )

                # Update active workspace (focused is more reliable here)
                for ws in workspace_list:
                    if ws["is_focused"]:
                        active_workspace_id = ws["id"]
                        break
    
            elif "WorkspaceActivated" in event:
                activated_id = event["WorkspaceActivated"]["id"]

                for ws in workspace_list:
                    ws["is_focused"] = (ws["id"] == activated_id)
                    if ws["is_focused"]:
                        active_workspace_id = ws["id"]
                        focused_workspace_idx = ws["idx"]

            elif "WindowsChanged" in event:
                for win in event["WindowsChanged"]["windows"]:
                    window_map[win["id"]] = win["title"]
                    if win.get("is_focused"):
                        window_title = win["title"]

            elif "WindowOpenedOrChanged" in event:
                win = event["WindowOpenedOrChanged"]["window"]
                window_map[win["id"]] = win["title"]
                
                # If it's the currently focused window, update the visible title
                if win["is_focused"]:
                    window_title = win["title"]

            elif "WindowFocusChanged" in event:
                win_id = event["WindowFocusChanged"]["id"]
                if win_id is not None:
                    window_title = window_map.get(win_id, "Unknown")
                else:
                    window_title = None

            elif "OverviewOpenedOrClosed" in event:
                is_overview = event["OverviewOpenedOrClosed"]["is_open"]

            write_status()

        except Exception as e:
            print(f"[WARN] Could not parse or update: {e}")
