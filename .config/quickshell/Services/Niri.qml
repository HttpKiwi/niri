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
    property int focused_workspace_idx: 0
    property bool is_overview: false

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
            property int focused_workspace_idx
            property bool is_overview
            
            onTitleChanged: root.title = title
            onActive_workspaceChanged: root.active_workspace = active_workspace
            onWorkspacesChanged: root.workspaces = workspaces
            onFocused_workspace_idxChanged: root.focused_workspace_idx = focused_workspace_idx
            onIs_overviewChanged: root.is_overview = is_overview
        }
    }
}
