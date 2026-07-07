import QtQuick
import Quickshell
import Quickshell.Io
pragma Singleton

/**
 * Settings - Centralized configuration for the entire shell
 * All hardcoded values should be defined here for easy customization
 */
QtObject {
    id: root

    // ========================================
    // Wallpaper persistence
    // ========================================
    readonly property string homeDir: Quickshell.env("HOME") || ""
    readonly property string username: Quickshell.env("USER") || ""
    readonly property string wallpapersDir: homeDir + "/Pictures/Wallpapers"
    readonly property string currentWallpaperFile: wallpapersDir + "/current_wallpaper.json"
    readonly property string defaultWallpaper: wallpapersDir + "/cozycabininthewoods.webp"
    readonly property string matugenCacheScript: Quickshell.shellDir + "/scripts/matugen-cache.sh"

    property string backgroundImagePath: ""

    property var wallpaperLoader: Process {
        running: true
        command: ["cat", root.currentWallpaperFile]

        stdout: SplitParser {
            id: wallpaperParser
            property string collectedOutput: ""
            onRead: data => { collectedOutput += data }
        }

        onRunningChanged: {
            if (!running) {
                const output = wallpaperParser.collectedOutput.trim()
                if (output) {
                    try {
                        const data = JSON.parse(output)
                        if (data.path) {
                            root.backgroundImagePath = data.path
                        } else {
                            root.backgroundImagePath = root.defaultWallpaper
                            defaultWallpaperSaver.running = true
                        }
                    } catch (e) {
                        root.backgroundImagePath = root.defaultWallpaper
                        defaultWallpaperSaver.running = true
                    }
                } else {
                    root.backgroundImagePath = root.defaultWallpaper
                    defaultWallpaperSaver.running = true
                }
                wallpaperParser.collectedOutput = ""
            }
        }
    }

    // ========================================
    // Wallpaper saver (creates default JSON if missing)
    // ========================================
    property var defaultWallpaperSaver: Process {
        running: false
        command: ["sh", "-c", `echo '{"path": "${root.defaultWallpaper}"}' > '${root.currentWallpaperFile}'`]
    }

    // ========================================
    // Notification Settings
    // ========================================
    readonly property int notificationTimeout: 5000
    readonly property int notificationMaxStack: 4
    readonly property int notificationWidth: 380
    readonly property int notificationHeight: 100
    readonly property int notificationTopMargin: 50
    readonly property int notificationRightMargin: 16
    readonly property int notificationSpacing: 105
    readonly property int notificationDismissThreshold: 100
    // Notification history limits
    readonly property int notificationHistoryMaxPerApp: 100
    readonly property int notificationHistoryMaxTotal: 1000
    readonly property int notificationHistoryMaxAgeDays: 2 // 0 = disabled, >0 = auto-cleanup older than N days
    // ========================================
    // OSD Settings
    // ========================================
    readonly property int osdTimeout: 1000
    // Vertical pill on the left frame
    readonly property int osdWidth: 48
    readonly property int osdHeight: 200
    // ========================================
    // Bar Settings
    // ========================================
    readonly property int barHeight: 30
    readonly property int barExclusiveZone: 35
    readonly property int barPillHeight: 20 // Reduced from 24 to add more padding inside bar
    readonly property int barPillRadius: 12
    readonly property int barPillPadding: 16
    readonly property int barContentMargin: 12
    readonly property int barModuleSpacing: 6
    readonly property int barWorkspaceSpacing: 8
    // Workspace indicator
    readonly property int workspaceIndicatorHeight: 12
    readonly property int workspaceIndicatorInactiveWidth: 12
    readonly property int workspaceIndicatorActiveWidth: 24
    // ========================================
    // Hidden Application IDs (hidden from launcher)
    // ========================================
    readonly property var hiddenAppIds: [
        "avahi-discover",
        "bssh",
        "bvnc"
    ]

    // ========================================
    // Animation Settings
    // ========================================
    readonly property int animationDurationShort: 150
    readonly property int animationDurationMedium: 250
    readonly property int animationDurationLong: 400
    // Easing curves
    readonly property int easingStandard: Easing.OutCubic
    readonly property int easingEmphasized: Easing.BezierSpline
    readonly property int easingDecelerate: Easing.OutCubic
    readonly property int easingAccelerate: Easing.InCubic
    // ========================================
    // Layout Settings
    // ========================================
    readonly property int screenBorderWidth: 6
    readonly property int screenCornerRadius: 20
    readonly property int screenSmoothing: 20
    readonly property int cardRadius: 12
    readonly property int cardBorderWidth: 1
    readonly property int cardMargin: 4
    readonly property int cardPadding: 16
    // Tinted frosted glass (over niri layer blur)
    readonly property real glassOpacity: 0.45
    readonly property real glassBorderOpacity: 0.16
    // How much matugen primary tints the glass (0 = neutral, 0.2 = clear wash)
    readonly property real glassTintStrength: 0.14
    // ========================================
    // Typography Settings
    // ========================================
    readonly property int fontSizeCaption: 10
    readonly property int fontSizeSmall: 11
    readonly property int fontSizeMedium: 12
    readonly property int fontSizeBar: 12
    readonly property int fontSizeLarge: 13
    readonly property int fontSizeTitle: 14
    readonly property int fontSizeIcon: 24
    readonly property string fontFamilyDefault: "Adwaita Sans"
    readonly property string fontFamilyIcons: "Material Symbols Rounded"
    // ========================================
    // Launcher / HTTP
    // ========================================
    readonly property int launcherSearchDebounceMs: 350
    readonly property int launcherTabTransitionMs: 150
    readonly property int httpConnectTimeoutMs: 5000
    readonly property int httpMaxTimeMs: 10000
    readonly property bool httpLowPriority: true
    readonly property string klipyApiBase: "https://api.klipy.com/api/v1"
    readonly property string secretsFile: Quickshell.shellDir + "/secrets.env"
    property string _klipyApiKeyFromFile: ""
    property bool klipyReady: false
    readonly property string klipyApiKey: {
        const envKey = Quickshell.env("KLIPY_API_KEY") || ""
        if (envKey && envKey !== "your-klipy-api-key")
            return envKey
        return _klipyApiKeyFromFile
    }
    readonly property string klipyLocale: "en_US"
    readonly property int klipySearchLimit: 20
    readonly property int launcherGifGridColumns: 3
    readonly property int launcherGifGridSpacing: 8
    readonly property int launcherGifGridMaxHeight: 340
    readonly property int launcherGifCellMinHeight: 72
    readonly property int launcherGifCellMaxHeight: 200
    // ========================================
    // Flickable Settings
    // ========================================
    readonly property int flickMaxVelocity: 2500
    readonly property int flickDeceleration: 1500
    readonly property int flickSlideDistance: 400
    // ========================================
    // Lockscreen Settings
    // ========================================
    readonly property int lockscreenBlurRadius: 30
    readonly property string lockscreenTimeFormat: "HH:mm"
    readonly property string lockscreenDateFormat: "dddd, MMMM d"
    readonly property int lockscreenCardWidth: 380
    readonly property int lockscreenCardPadding: 28
    readonly property int lockscreenClockSize: 64
    readonly property int lockscreenDateSize: 16
    readonly property int lockscreenInputHeight: 48
    readonly property int lockscreenInputRadius: 24
    // Delay after bar hides before session lock surface appears
    readonly property int lockscreenEngageDelay: 280
    // Delay after lock release before bar/blob chrome fades back in
    readonly property int lockscreenChromeRestoreDelay: 180
    readonly property int lockscreenBackdropBlur: 48
    // ========================================
    // Idle/Sleep Settings
    // ========================================
    readonly property int idleLockTimeout: 300
    readonly property int idleSleepTimeout: 600
    // ========================================
    // Control Center Settings
    // ========================================
    readonly property int controlCenterWidth: 420
    // Inset from screen frame — keep equal to pocketPadding for symmetric blob margins
    readonly property int controlCenterPadding: 14
    readonly property int controlCenterBottomMargin: 6
    readonly property int confirmDialogWidth: 320
    readonly property int confirmDialogPadding: 24
    readonly property int systemActionsSpacing: 12
    // ========================================
    // Blur Settings
    // ========================================
    readonly property bool blurEnabled: true
    readonly property real blurBorderOpacity: 0.35
    // ========================================
    // Surface Transparency
    // ========================================
    readonly property real surfaceTransparency: 0.6
    // ========================================
    // Background Settings
    // ========================================
    readonly property string backgroundType: "image"
    readonly property string backgroundColor: "#091518"
    property int wallpaperChangeDirection: 1 // 1 = right, -1 = left
    // ========================================
    // Chrome Shader (prototype)
    // ========================================
    readonly property bool chromeShaderEnabled: true
    // Dot-matrix mesh (Flex Volume–style grain)
    readonly property real chromeCellSize: 5
    readonly property real chromeDotSize: 0.35
    // Aurora drift speed
    readonly property real chromeAnimSpeed: 0.2
    // Ribbon color strength (1 = full matugen color on ribbons)
    readonly property real chromeIntensity: 1

    signal secretsLoaded()

    property var secretsLoader: Process {
        running: false
        command: ["bash", "-c", "f='" + root.secretsFile + "'; if [ -f \"$f\" ]; then set -a; . \"$f\"; set +a; fi; printf '%s' \"$KLIPY_API_KEY\""]

        stdout: SplitParser {
            onRead: data => {
                const key = data.trim()
                if (key && key !== "your-klipy-api-key")
                    root._klipyApiKeyFromFile = key
                root.klipyReady = true
                root.secretsLoaded()
            }
        }

        onExited: (exitCode, exitStatus) => {
            if (!root.klipyReady) {
                root.klipyReady = true
                root.secretsLoaded()
            }
        }
    }

    Component.onCompleted: {
        const envKey = Quickshell.env("KLIPY_API_KEY") || ""
        if (envKey && envKey !== "your-klipy-api-key") {
            klipyReady = true
            return
        }
        secretsLoader.running = true
    }
}
