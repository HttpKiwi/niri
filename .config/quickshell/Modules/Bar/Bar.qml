pragma ComponentBehavior: Bound

import Quickshell
import QtQuick
import QtQuick.Layouts
import "BarModules"
import Services 1.0
import qs.common

PanelWindow {
    id: barWindow
    // Property to specify which monitor this bar is for
    property string targetMonitor: ""

    anchors {
        top: true
        left: true
        right: true
    }
    color: "transparent"

    implicitHeight: 40
    exclusiveZone: 35

    Rectangle {
        id: barContent
        visible: !Niri.is_overview
        anchors {
            right: parent.right
            left: parent.left
            top: parent.top
            verticalCenter: parent.verticalCenter
        }

        color: Color.background
        height: 30

        // center module
        Text {
            id: title
            anchors.centerIn: parent
            text: Niri.title
            color: Color.on_surface
        }

        // left module
        Row {
            id: workspaces
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: 12
            spacing: 8

            Repeater {
                model: {
                    try {
                        if (barWindow.targetMonitor) {
                            const workspaces = Niri.getWorkspacesForMonitor(barWindow.targetMonitor);
                            return workspaces || [];
                        } else {
                            return Niri.workspaces || [];
                        }
                    } catch (e) {
                        console.warn("Error getting workspaces:", e);
                        return [];
                    }
                }

                delegate: Item {
                    id: workspaceRoot
                    required property var modelData
                    readonly property bool isActive: {
                        if (barWindow.targetMonitor) {
                            // The active workspace must be on this bar's target monitor
                            return modelData.idx === Niri.focused_workspace_idx && modelData.output === Niri.focused_output_name;
                        }
                        // No target monitor, so use is_focused for global focus
                        return modelData.is_focused;
                    }

                    width: dot.width
                    height: 12

                    // Visual indicator - animated dot
                    Rectangle {
                        id: dot
                        anchors.verticalCenter: parent.verticalCenter
                        width: workspaceRoot.isActive ? 24 : 12
                        height: parent.height
                        radius: height / 2
                        color: workspaceRoot.isActive ? Color.secondary : Color.secondary_fixed
                        Behavior on width {
                            NumberAnimation {
                                duration: 200
                                easing.type: Easing.OutCubic
                            }
                        }
                        Behavior on color {
                            ColorAnimation {
                                duration: 150
                                easing.type: Easing.OutCubic
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true

                        onEntered: {
                            if (!workspaceRoot.isActive) {
                                dot.color = Color.primary_container;
                            }
                        }

                        onExited: {
                            if (!workspaceRoot.isActive) {
                                dot.color = Color.secondary_fixed;
                            }
                        }

                        onClicked: {
                            try {
                                // Focus the workspace by index
                                const command = ["niri", "msg", "action", "focus-workspace", `${workspaceRoot.modelData.idx}`];

                                Qt.createQmlObject(`
                            import Quickshell.Io;
                            Process {
                                command: ${JSON.stringify(command)}
                                running: true
                            }
                        `, workspaceRoot);
                            } catch (e) {
                                console.error("Error switching workspace:", e);
                            }
                        }
                    }
                }
            }
        }

        // right module
        RowLayout {

            spacing: 12
            anchors.right: parent.right
            anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            // Volume {
            //     Layout.preferredWidth: 150
            // }
            Player {}
            Volume {}
            Status {
                Layout.minimumWidth: 100
            }
            Time {}
            }
    }
}
