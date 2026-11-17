pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

/**
 * Eye - the eye comfort filter: wlsunset holding every screen at a warm
 * temperature while the pref is on (low and high a degree apart, no location,
 * so it never drifts back to 6500 K).
 */
Singleton {
    Process {
        command: ["wlsunset", "-t", String(Tune.eyeTemp), "-T", String(Tune.eyeTemp + 1)]
        running: Store.prefs.eye === true
    }
}
