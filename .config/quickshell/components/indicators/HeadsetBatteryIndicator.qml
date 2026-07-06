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

        Text {
            id: icon
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: -1
            text: "\ue311"
            color: Theme.textPrimary
            font.family: Settings.fontFamilyIcons
            font.pixelSize: 14
        }

        Text {
            id: percentage
            visible: root.available
            anchors.verticalCenter: parent.verticalCenter
            color: Theme.textPrimary
            font.family: Settings.fontFamilyDefault
            font.pixelSize: Settings.fontSizeBar
            text: root.batteryLevel + "%"
        }
    }
}
