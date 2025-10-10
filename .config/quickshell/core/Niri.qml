pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import QtQuick

QtObject {
    id: root

    // Properties that will be updated from JSON file
    property string title: "Default Title"
    property int active_workspace: 0
    property var workspaces: []
    property var workspaces_by_monitor: ({})
    property int focused_workspace_idx: 0
    property string focused_output_name: ""
    property bool is_overview: false

    // Helper function to get workspaces for a specific monitor
    function getWorkspacesForMonitor(monitorName) {
        try {
            if (workspaces_by_monitor && workspaces_by_monitor[monitorName]) {
                return workspaces_by_monitor[monitorName]
            }
        } catch (e) {
            console.warn("Error getting workspaces for monitor", monitorName, ":", e)
        }
        return []
    }

    // Helper function to get all monitor names
    function getMonitorNames() {
        try {
            if (workspaces_by_monitor) {
                return Object.keys(workspaces_by_monitor)
            }
        } catch (e) {
            console.warn("Error getting monitor names:", e)
        }
        return []
    }

    // Helper function to determine if a workspace is active
    function isWorkspaceActive(workspace, monitorName) {
        if (monitorName) {
            return workspace.is_focused && workspace.output === monitorName;
        }
        return workspace.is_focused;
    }

    Component.onCompleted: {
        // Initial load
        fileView.reload()
    }

    // FileView to read JSON file
    property QtObject fileView: FileView {
        id: fileView
        path: "/tmp/niri_status.json"
        watchChanges: true
        onFileChanged: reload()
        onAdapterUpdated: writeAdapter()

        JsonAdapter {
            id: adapter
            property string title
            property int active_workspace
            property var workspaces
            property var workspaces_by_monitor
            property int focused_workspace_idx
            property string focused_output_name
            property bool is_overview
            
            onTitleChanged: root.title = title
            onActive_workspaceChanged: root.active_workspace = active_workspace
            onWorkspacesChanged: root.workspaces = workspaces
            onWorkspaces_by_monitorChanged: root.workspaces_by_monitor = workspaces_by_monitor
            onFocused_workspace_idxChanged: root.focused_workspace_idx = focused_workspace_idx
            onFocused_output_nameChanged: root.focused_output_name = focused_output_name
            onIs_overviewChanged: root.is_overview = is_overview
        }
    }
}
