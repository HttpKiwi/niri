pragma Singleton

import QtQuick
import Quickshell
import qs.config

/**
 * Ambience - time of day and weather for the backdrop. Automatic from the
 * clock; IPC can force either (`ambience setPhase night`, `setWeather rain`).
 */
Singleton {
    id: root

    property string forcedPhase: ""
    property string forcedWeather: ""

    readonly property date now: clock.date
    readonly property string autoPhase: {
        const h = now.getHours() + now.getMinutes() / 60;
        if (h >= Tune.nightFrom || h < Tune.dayFrom) return "night";
        if (h >= Tune.goldenFrom) return "golden";
        return "day";
    }
    readonly property string phase: forcedPhase || autoPhase
    readonly property string weather: forcedWeather || "clear"
    readonly property var grade: Tune.grades[phase]

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }
}
