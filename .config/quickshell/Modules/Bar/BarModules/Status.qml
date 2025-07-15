import QtQuick
import Quickshell
import Quickshell.Widgets
import Services 1.0

WrapperItem {
    id: statusRoot

    height: parent.height
    anchors.verticalCenter: parent.verticalCenter

    Row {
        spacing: 12

        anchors {
            horizontalCenter: parent.horizontalCenter
        }

        Text {
            text: `CPU: ${Math.round(ResourceUsage.cpuUsage * 100)}%`
            color: "#f89f7f"
        }

        Text {
            text: `RAM: ${Math.round(ResourceUsage.memoryUsedPercentage * 100)}%`
            color: "#f89f7f"
        }

    }

}
