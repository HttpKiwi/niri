import QtQuick
import Quickshell
import Services 1.0

Item {
    id: statusRoot

    width: 140
    height: parent.height

    Rectangle {
        anchors.fill: parent
        color: "lightgray"
        radius: 8

        Row {
            spacing: 12

            anchors {
                verticalCenter: parent.verticalCenter
                horizontalCenter: parent.horizontalCenter
            }

            Text {
                text: `CPU: ${Math.round(ResourceUsage.cpuUsage * 100)}%`
                color: "black"
            }

            Text {
                text: `RAM: ${Math.round(ResourceUsage.memoryUsedPercentage * 100)}%`
                color: "black"
            }
        }
    }
}
