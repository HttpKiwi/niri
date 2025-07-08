import QtQuick 2.15
import QtQuick.Controls
import Quickshell.Io

Item {
    id: volumeModule

    property int volumeLevel: 50 // Default volume level

    Row {
        spacing: 8
        anchors.verticalCenter: parent.verticalCenter

        // Volume Icon
        Image {
            id: volumeIcon

            source: volumeLevel > 0 ? "volume-high-icon.png" : "volume-muted-icon.png"
            width: 16
            height: 16
            anchors.verticalCenter: parent.verticalCenter
        }

        // Volume Slider
        Slider {
            id: volumeSlider

            width: 100
            value: volumeLevel
            from: 0
            to: 100
            stepSize: 1
            anchors.verticalCenter: parent.verticalCenter
            onValueChanged: {
                volumeLevel = value;
                Qt.createQmlObject(`
                    import Quickshell.Io;
                    Process {
                        command: ["niri", "msg", "action", "set-volume", "${value}"]
                        running: true
                    }
                `, volumeSlider);
            }
        }

        // Volume Level Text
        Text {
            id: volumeText

            text: `${volumeLevel}%`
            anchors.verticalCenter: parent.verticalCenter
        }

    }

}

