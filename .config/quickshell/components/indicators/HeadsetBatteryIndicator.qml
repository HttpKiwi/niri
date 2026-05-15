import QtQuick
import Quickshell
import Quickshell.Widgets
import Quickshell.Io
import qs.config

/**
 * HeadsetBatteryIndicator - Shows headset battery level
 * Uses headsetcontrol -b to get battery status
 */
WrapperMouseArea {
    id: root

    property int batteryLevel: -1
    property bool available: false
    hoverEnabled: true

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: checkBattery()
    }

    Component.onCompleted: checkBattery()

    function checkBattery() {
        process.running = true
    }

    Process {
        id: process
        command: ["headsetcontrol", "-b"]
        running: false

        stdout: SplitParser {
            id: outputParser
            property string collectedOutput: ""
            onRead: data => {
                collectedOutput += data
            }
        }

        onRunningChanged: {
            if (!running) {
                const output = outputParser.collectedOutput
                const levelMatch = output.match(/Level:\s*(\d+)%/)
                const availableMatch = output.match(/Status:\s*(\w+)/)

                if (levelMatch && availableMatch && availableMatch[1] === "BATTERY_AVAILABLE") {
                    root.batteryLevel = parseInt(levelMatch[1])
                    root.available = true
                } else {
                    root.available = false
                }
                outputParser.collectedOutput = ""
            }
        }
    }

Row {
        spacing: 4
        anchors.centerIn: parent

        Image {
            id: icon
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: -1
            source: "data:image/svg+xml;utf8,%3Csvg xmlns='http://www.w3.org/2000/svg' height='14px' viewBox='0 -960 960 960' width='14px' fill='%23e3e3e3'%3E%3Cpath d='M360-120H200q-33 0-56.5-23.5T120-200v-280q0-75 28.5-140.5t77-114q48.5-48.5 114-77T480-840q75 0 140.5 28.5t114 77q48.5 48.5 77 114T840-480v280q0 33-23.5 56.5T760-120H600v-320h160v-40q0-117-81.5-198.5T480-760q-117 0-198.5 81.5T200-480v40h160v320Zm-80-240h-80v160h80v-160Zm400 0v160h80v-160h-80Zm-400 0h-80 80Zm400 0h80-80Z'/%3E%3C/svg%3E"
            sourceSize: Qt.size(14, 14)
        }

        Text {
            id: percentage
            visible: root.available
            anchors.verticalCenter: parent.verticalCenter
            color: Theme.textPrimary
            font.pixelSize: Settings.fontSizeSmall
            text: root.batteryLevel + "%"
        }
    }
}
