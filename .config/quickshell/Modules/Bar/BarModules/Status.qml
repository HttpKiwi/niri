import QtQuick
import Quickshell.Widgets
import Services 1.0

WrapperItem {
    id: statusRoot

    height: parent.height

    Row {
        spacing: 12

        anchors {
            horizontalCenter: parent.horizontalCenter
        }

        Text {
            width: 50
            text: `CPU: ${Math.round(ResourceUsage.cpuUsage * 100)}%`
            color: Color.on_surface
        }

        Text {
            text: `RAM: ${Math.round(ResourceUsage.memoryUsedPercentage * 100)}%`
            color: Color.on_surface
        }

    }

}
