pragma Singleton

import QtQuick
import Quickshell
import qs.config

/**
 * Ambience - time of day and weather for the backdrop. Automatic from the
 * sun (Tune.latitude/longitude); IPC can force either (`ambience setPhase night`, `setWeather rain`).
 */
Singleton {
    id: root

    property string forcedPhase: ""
    property string forcedWeather: ""

    readonly property date now: clock.date
    // Sunrise and sunset, local hours (NOAA approximation; plenty for a mood)
    readonly property var sun: {
        const d = now, rad = Math.PI / 180;
        const n = Math.floor((d - new Date(d.getFullYear(), 0, 0)) / 864e5);
        const decl = 23.44 * rad * Math.sin(2 * Math.PI * (284 + n) / 365);
        const b = 2 * Math.PI * (n - 81) / 364;
        const eot = 9.87 * Math.sin(2 * b) - 7.53 * Math.cos(b) - 1.5 * Math.sin(b);   // minutes
        const lat = Tune.latitude * rad;
        const c = (Math.sin(-0.833 * rad) - Math.sin(lat) * Math.sin(decl)) / (Math.cos(lat) * Math.cos(decl));
        const ha = Math.acos(Math.max(-1, Math.min(1, c))) / rad / 15;                  // hours
        const noon = 12 - Tune.longitude / 15 - eot / 60 - d.getTimezoneOffset() / 60;
        return { rise: noon - ha, set: noon + ha };
    }
    readonly property string autoPhase: {
        const h = now.getHours() + now.getMinutes() / 60;
        if (h >= sun.set + Tune.nightAfter || h < sun.rise - Tune.dayBefore) return "night";
        if (h >= sun.set - Tune.goldenBefore) return "golden";
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
