pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Niri 0.1 as NiriPlugin

Item {
    id: root

    visible: false

    property var _wsArray: []
    property var _wsByMonitor: ({})
    property string _focusedOutput: ""
    property int _version: 0

    property NiriPlugin.Niri niri: NiriPlugin.Niri {
        id: niriInstance
        Component.onCompleted: {
            connect()
        }
        onRawEventReceived: function(event) {
            if (event.WorkspacesChanged) {
                root._handleWorkspacesChanged(event.WorkspacesChanged.workspaces)
            } else if (event.WorkspaceActivated) {
                root._handleWorkspaceActivated(event.WorkspaceActivated.id)
            }
        }
    }

    readonly property var workspaceModel: niriInstance.workspaces
    readonly property var windowModel: niriInstance.windows
    readonly property var focusedWindow: niriInstance.focusedWindow
    readonly property string title: niriInstance.focusedWindow?.title ?? ""
    readonly property bool is_overview: false

    readonly property var workspaces_by_monitor: root._wsByMonitor
    readonly property string focused_output_name: root._focusedOutput

    function getWorkspacesForMonitor(monitorName) {
        var v = root._version
        var m = root._wsByMonitor
        if (!m || !m[monitorName]) return []
        return m[monitorName]
    }

    function getMonitorNames() {
        var m = root._wsByMonitor
        return m ? Object.keys(m) : []
    }

    function niriNameFor(screenName) {
        if (!screenName) return ""
        var names = getMonitorNames()
        for (var i = 0; i < names.length; i++) {
            if (screenName.includes(names[i]) || names[i].includes(screenName)) return names[i]
        }
        return screenName
    }

    function _handleWorkspacesChanged(rawWorkspaces) {
        if (!rawWorkspaces) return
        var arr = []
        var grouped = {}
        var foutput = ""
        var fidx = 0
        var aid = 0

        for (var i = 0; i < rawWorkspaces.length; i++) {
            var ws = rawWorkspaces[i]
            var isActive = ws.is_active || false
            var isFocused = ws.is_focused || false
            var entry = {
                id: ws.id,
                idx: ws.idx,
                index: ws.idx,
                name: ws.name,
                output: ws.output,
                is_active: isActive,
                isActive: isActive,
                is_focused: isFocused,
                isFocused: isFocused,
                isUrgent: ws.is_urgent || false
            }
            arr.push(entry)

            var out = ws.output
            if (!grouped[out]) grouped[out] = []
            grouped[out].push(entry)

            if (isFocused) {
                foutput = out
                fidx = ws.idx
                aid = ws.id
            }
        }

        arr.sort(function(a, b) { return a.idx - b.idx })
        root._wsArray = arr
        root._wsByMonitor = grouped
        root._focusedOutput = foutput || root._focusedOutput
        root._version++
    }

    function _handleWorkspaceActivated(actId) {
        var arr = root._wsArray
        var out = ""
        for (var i = 0; i < arr.length; i++) {
            arr[i].is_focused = (arr[i].id === actId)
            arr[i].isFocused = (arr[i].id === actId)
            if (arr[i].isFocused) {
                out = arr[i].output
            }
        }
        for (var i = 0; i < arr.length; i++) {
            if (arr[i].output === out) {
                arr[i].is_active = (arr[i].id === actId)
                arr[i].isActive = (arr[i].id === actId)
            }
        }
        root._focusedOutput = out
        root._version++
    }

    function focusWorkspace(index) { return niriInstance.focusWorkspace(index) }
    function focusWorkspaceById(id) { return niriInstance.focusWorkspaceById(id) }
    function focusWorkspaceByName(name) { return niriInstance.focusWorkspaceByName(name) }
    function closeWindow(id) { return niriInstance.closeWindow(id) }
    function closeWindowOrFocused() { return niriInstance.closeWindowOrFocused() }
    function toggleOverview() { return niriInstance.toggleOverview() }
    function sendRawAction(action) { return niriInstance.sendRawAction(action) }
}
