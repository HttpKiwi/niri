import QtQuick
import Quickshell

Text {
    id: datetime

    text: Qt.formatTime(clock.date, "hh:mm")

    SystemClock {
        id: clock

        precision: SystemClock.Minutes
    }

}
