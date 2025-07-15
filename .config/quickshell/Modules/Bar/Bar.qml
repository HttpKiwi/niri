pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import QtQuick 
import QtQuick.Layouts
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

        color: "#202b2d"
        height: 30

        // center module
        Text {
            id: title
            anchors.centerIn: parent
            text: Niri.title
            color: "#f89f7f"
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
                        color: "#f89f7f"

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
                }
            }
        }

        // right module
        RowLayout {
          
            spacing:12 
            anchors.right: parent.right
            anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            // Volume {
            //     Layout.preferredWidth: 150
            // }
            Volume {}
            Status {
              Layout.minimumWidth: 100
            }
            
            Time {}
        }
    }
}
