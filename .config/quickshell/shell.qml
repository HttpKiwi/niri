pragma ComponentBehavior: Bound

import Quickshell

// New refactored modules
import qs.features.bar
import qs.features.decorations
import qs.features.notifications
import qs.features.osd

ShellRoot {
    MultiMonitorBar {
        id: multiMonitorBar
    }
    RoundedScreen {}
    MultiScreenBorder {}
    VolumeOSD {}
    NotificationManager {
        id: notificationManager
    }

}

