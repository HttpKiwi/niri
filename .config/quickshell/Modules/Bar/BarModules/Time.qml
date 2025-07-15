import QtQuick
import Quickshell

Text {
    id: datetime

    text: Qt.formatTime(clock.date, "hh:mm")
    color: "#f89f7f"

    anchors {
        verticalCenter: parent.verticalCenter
        right: parent.right
    }

    SystemClock {
        id: clock

        precision: SystemClock.Minutes
    }

}
