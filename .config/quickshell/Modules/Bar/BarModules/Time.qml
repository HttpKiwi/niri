import QtQuick
import Quickshell
import Services 1.0

Text {
    id: datetime

    text: Qt.formatTime(clock.date, "hh:mm")
    color: Color.on_surface

    SystemClock {
        id: clock

        precision: SystemClock.Minutes
    }

}
