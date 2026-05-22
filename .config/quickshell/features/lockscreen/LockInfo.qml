import QtQuick
import QtQuick.Layouts
import qs.config

ColumnLayout {
    id: root

    spacing: 8

    property var currentTime: new Date()

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            root.currentTime = new Date()
        }
    }

    Text {
        id: clockText
        Layout.alignment: Qt.AlignHCenter
        text: Qt.formatTime(root.currentTime, Settings.lockscreenTimeFormat)
        color: "#ffffff"
        font.pixelSize: Settings.lockscreenClockSize
        font.weight: Font.Light
        horizontalAlignment: Text.AlignHCenter
    }

    Text {
        id: dateText
        Layout.alignment: Qt.AlignHCenter
        text: Qt.formatDate(root.currentTime, Settings.lockscreenDateFormat)
        color: Qt.rgba(1.0, 1.0, 1.0, 0.7)
        font.pixelSize: Settings.lockscreenDateSize
        font.weight: Font.Normal
        horizontalAlignment: Text.AlignHCenter
    }
}
