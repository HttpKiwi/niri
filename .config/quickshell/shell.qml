//@ pragma IconTheme Papirus
pragma ComponentBehavior: Bound

import Quickshell

// New refactored modules
import qs.features.bar
import qs.features.background
import qs.features.decorations
import qs.features.notifications
import qs.features.osd
import qs.features.launcher

ShellRoot {
    Background {}
    BackgroundShadow {}
    MultiMonitorBar {
        id: multiMonitorBar
    }
    RoundedScreen {}
    MultiScreenBorder {}
    VolumeOSD {}
    NotificationManager {
        id: notificationManager
    }

    AppLauncher {
        id: appLauncher
    }

    NotificationHistoryPanel {
        id: notificationHistoryPanel
    }

}

