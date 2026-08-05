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
    readonly property string recordingsDir: homeDir + "/Videos/Recordings"
    property int screenRecordFps: 60

    property string backgroundImagePath: ""
    // First-frame JPEG for video wallpapers (matugen + lockscreen + inactive monitors)
    property string backgroundPosterPath: ""
    // Decode/animate video & GIF wallpapers
    property bool animatedWallpapersEnabled: true
    // Legacy pref — playback always runs on all outputs now (avoids focus-switch distraction)
    property bool animatedWallpaperFocusedOnly: false

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
                            if (data.poster)
                                root.backgroundPosterPath = data.poster.startsWith("file://")
                                    ? data.poster
                                    : ("file://" + data.poster)
                            else
                                root.backgroundPosterPath = ""
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
    property int notificationTimeout: 5000
    readonly property int notificationMaxStack: 4
    readonly property int notificationWidth: 380
    readonly property int notificationMinHeight: 72
    readonly property int notificationItemSpacing: 10
    readonly property int notificationGroupMaxListHeight: 300
    readonly property int notificationHeight: notificationMinHeight // legacy alias
    readonly property int notificationTopMargin: 50
    readonly property int notificationRightMargin: 16
    readonly property int notificationSpacing: notificationItemSpacing // legacy alias
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
    property int barHeight: 30
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
    property int animationDurationShort: 150
    property int animationDurationMedium: 250
    property int animationDurationLong: 400
    // Easing curves
    readonly property int easingStandard: Easing.OutCubic
    readonly property int easingEmphasized: Easing.BezierSpline
    readonly property int easingDecelerate: Easing.OutCubic
    readonly property int easingAccelerate: Easing.InCubic
    // ========================================
    // Layout Settings
    // ========================================
    property int screenBorderWidth: 6
    property int screenCornerRadius: 24
    property int screenSmoothing: 20
    property int cardRadius: 12
    readonly property int cardBorderWidth: 1
    readonly property int cardMargin: 4
    readonly property int cardPadding: 16
    // Tinted frosted glass (over niri layer blur)
    property real glassOpacity: 0.45
    property real glassBorderOpacity: 0.16
    // How much matugen primary tints the glass (0 = neutral, 0.2 = clear wash)
    property real glassTintStrength: 0.14

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
    // Cap rows pushed into the launcher ListModel (avoids UI freezes on huge lists)
    readonly property int launcherMaxModelItems: 50
    // Keep cliphist DB / clipboard tab in sync — see .config/cliphist/config
    readonly property int clipboardMaxItems: 200
    readonly property string clipboardThumbDir: "/tmp/quickshell-clip-thumbs"
    readonly property int clipboardThumbSize: 40
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
    readonly property int lockscreenBackdropCrossfadeDuration: animationDurationLong
    // ========================================
    // Idle/Sleep Settings
    // ========================================
    property int idleLockTimeout: 300
    property int idleSleepTimeout: 600
    property bool inhibitIdleWhenAudio: true
    property bool enableAutoLock: true
    property bool enableAutoSleep: true
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
    property bool blurEnabled: true
    property real blurBorderOpacity: 0.35
    // ========================================
    // Surface Transparency
    // ========================================
    property real surfaceTransparency: 0.6
    // ========================================
    // Background Settings
    // ========================================
    readonly property string backgroundColor: "#091518"
    property int wallpaperChangeDirection: 1 // 1 = right, -1 = left
    // ========================================
    // Chrome Shader (prototype)
    // ========================================
    property bool chromeShaderEnabled: true
    // Aurora clock — 15fps (1000/15 ≈ 67ms)
    property int chromeClockIntervalMs: 67
    // Dot-matrix mesh (Flex Volume–style grain)
    property real chromeCellSize: 5
    property real chromeDotSize: 0.35
    // Aurora drift speed
    property real chromeAnimSpeed: 0.2
    // Ribbon color strength (1 = full matugen color on ribbons)
    property real chromeIntensity: 1

    // ========================================
    // Settings window + prefs persistence
    // ========================================
    readonly property string shellPrefsFile: Quickshell.shellDir + "/common/shell-prefs.json"
    property bool _prefsLoaded: false
    property bool _prefsLoading: false
    property string prefsStatusMessage: ""

    readonly property var _prefsKeys: [
        "animationDurationShort", "animationDurationMedium", "animationDurationLong",
        "screenBorderWidth", "screenCornerRadius", "screenSmoothing", "cardRadius",
        "glassOpacity", "glassBorderOpacity", "glassTintStrength",
        "idleLockTimeout", "idleSleepTimeout", "inhibitIdleWhenAudio",
        "enableAutoLock", "enableAutoSleep",
        "blurEnabled", "blurBorderOpacity", "surfaceTransparency",
        "notificationTimeout", "screenRecordFps", "barHeight",
        "chromeShaderEnabled", "chromeClockIntervalMs",
        "chromeCellSize", "chromeDotSize", "chromeAnimSpeed", "chromeIntensity",
        "animatedWallpapersEnabled", "animatedWallpaperFocusedOnly"
    ]

    function setPref(key, value) {
        if (!(key in root) || root._prefsKeys.indexOf(key) < 0)
            return;
        root._prefsLoading = true;
        root[key] = value;
        root._prefsLoading = false;
        prefsSaveTimer.restart();
    }

    function savePrefs() {
        const prefs = {};
        for (let i = 0; i < root._prefsKeys.length; i++) {
            const k = root._prefsKeys[i];
            prefs[k] = root[k];
        }
        const json = JSON.stringify(prefs, null, 2);
        prefsSaver.command = [
            "sh", "-c",
            `mkdir -p "$(dirname '${root.shellPrefsFile}')" && cat > '${root.shellPrefsFile}' << 'EOF'\n${json}\nEOF`
        ];
        prefsSaver.running = true;
    }

    function _applyPrefsObject(obj) {
        if (!obj || typeof obj !== "object")
            return;
        root._prefsLoading = true;
        for (let i = 0; i < root._prefsKeys.length; i++) {
            const k = root._prefsKeys[i];
            if (obj[k] === undefined)
                continue;
            try {
                root[k] = obj[k];
            } catch (e) {
                console.warn("Settings: skip pref", k, e);
            }
        }
        root._prefsLoading = false;
        root._prefsLoaded = true;
    }

    property var prefsSaveTimer: Timer {
        interval: 400
        repeat: false
        onTriggered: root.savePrefs()
    }

    property var prefsLoader: Process {
        running: true
        command: ["sh", "-c", `test -f '${root.shellPrefsFile}' && cat '${root.shellPrefsFile}' || true`]
        stdout: StdioCollector {
            id: prefsOut
        }
        onExited: {
            const text = prefsOut.text.trim();
            if (!text)
                return;
            try {
                root._applyPrefsObject(JSON.parse(text));
            } catch (e) {
                root.prefsStatusMessage = "Failed to load shell prefs";
                console.warn("Settings: failed to load shell prefs", e);
            }
        }
    }

    property var prefsSaver: Process {
        running: false
        onExited: code => {
            if (code === 0) {
                if (root.prefsStatusMessage.indexOf("Failed to save") === 0)
                    root.prefsStatusMessage = "";
            } else {
                root.prefsStatusMessage = `Failed to save shell prefs (exit ${code})`;
                console.warn("Settings: prefs save failed", code);
            }
        }
    }

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
