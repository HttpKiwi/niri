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
import qs.features.wallpaper

ShellRoot {
    Background {}
    BackgroundShadow {}
    UnifiedBar {}
    RoundedScreen {}
    VolumeOSD {}
    
    function getNotificationScreen() {
        const screens = Quickshell.screens;
        if (!screens || screens.length === 0) return null;
        
        for (let i = 0; i < screens.length; i++) {
            if (screens[i].height > screens[i].width) {
                return screens[i];
            }
        }
        return screens[0];
    }

    NotificationManager {
        id: notificationManager
        targetScreen: getNotificationScreen()
    }

    AppLauncher {
        id: appLauncher
    }

    NotificationHistoryPanel {
        id: notificationHistoryPanel
    }

    WallpaperSelector {
        id: wallpaperSelector
    }

}

