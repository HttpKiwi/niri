pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import QtQuick 2.15
import "BarModules"
import Services 1.0

PanelWindow {
    id: barWindow

    anchors {
        top: true
        left: true
        right: true
    }
    color: "transparent"
    implicitHeight: 30
    exclusiveZone: 30

    Rectangle {
        id: barContent
        visible: !Niri.is_overview
        anchors {
            right: parent.right
            left: parent.left
            top: parent.top
            verticalCenter: parent.verticalCenter
        }

        color: "white"
        height: 30

        // center module
        Text {
            id: title
            anchors.centerIn: parent
            text: Niri.title
        }

        // left module
        Row {
            id: workspaces
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: 12
            spacing: 8

            Repeater {
                model: Niri.workspaces

                delegate: Item {
                    id: workspaceRoot
                    required property var modelData
                    property bool isActive: modelData.idx === Niri.focused_workspace_idx

                    width: dot.width
                    height: 12

                    // Visual indicator - animated dot
                    Rectangle {
                        id: dot
                        anchors.verticalCenter: parent.verticalCenter
                        width: workspaceRoot.isActive ? 24 : 12
                        height: parent.height
                        radius: height / 2
                        color: "black"

                        Behavior on width {
                            NumberAnimation {
                                duration: 200
                                easing.type: Easing.OutCubic
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            Qt.createQmlObject(`
                        import Quickshell.Io;
                        Process {
                            command: ["niri", "msg", "action", "focus-workspace", "${modelData.idx}"]
                            running: true
                        }
                    `, workspaceRoot);
                        }
                    }

                    // Debugging output (optional)
                    // Component.onCompleted: console.log("Workspace", modelData.idx, "created")
                    // onIsActiveChanged: console.log("Workspace", modelData.idx, "active:", isActive)
                }
            }
        }

        // right module
        Row {
            spacing: 12
            anchors.right: parent.right
            anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            Status {
                anchors.verticalCenter: parent.verticalCenter
            }
            Time {
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }
}
