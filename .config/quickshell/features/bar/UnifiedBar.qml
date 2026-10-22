pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Wayland
import qs.core
import qs.config
import qs.components.base
import qs.components.indicators
import qs.features.notifications
import qs.features.osd
import qs.features.wallpaper
import qs.features.controlcenter
import qs.features.settings
import qs.features.calendar
import qs.features.decorations


Scope {
    id: root

    // Strip invisible/special chars that can render as stray dots (e.g. U+02D9 DOT ABOVE, combining marks)
    function sanitizeTitle(s) {
        if (!s || typeof s !== "string") return s || ""
        // Keep only printable ASCII and Latin-1 supplement; removes combining, zero-width, spacing modifier letters
        return s.replace(/[^\x20-\x7e\xa0-\xff]/g, "")
    }

    Variants {
        model: Quickshell.screens || []

        PanelWindow {
            id: window

            function toggleCalendar() {
                if (panelState)
                    panelState.calendar = !panelState.calendar;
            }

            property var modelData
            readonly property string niriScreenName: Niri.niriNameFor(window.screen?.name ?? "")
            readonly property bool shellRetracted: LockState.shellRetracted
            // Chrome reveal animated by this window's own render loop (see LockState)
            property real chromeReveal: LockState.chromeHidden ? 0 : 1
            Behavior on chromeReveal {
                id: chromeRevealBehavior
                SequentialAnimation {
                    PauseAnimation {
                        duration: chromeRevealBehavior.targetValue > 0.5 ? Settings.lockscreenChromeRestoreDelay : 0
                    }
                    NumberAnimation {
                        duration: Settings.lockscreenEngageDelay
                        easing.type: Easing.InOutCubic
                    }
                }
            }

            color: "transparent"
            // The bar window reserves the bar's space itself. A separate zero-size
            // "exclusion" window did this before, but every layer window gets its
            // own GL context + Mesa worker threads (~25–30 MB each).
            exclusionMode: ExclusionMode.Normal
            exclusiveZone: topBar.implicitHeight - 5
            WlrLayershell.layer: WlrLayer.Top
            WlrLayershell.namespace: "quickshell:unifiedBar"
            WlrLayershell.keyboardFocus: window.panelState && (window.panelState.launcher || window.panelState.wallpaper || window.panelState.controlCenter || window.panelState.settings || window.panelState.calendar) ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
            visible: true

            screen: modelData || Quickshell.screens[0]

            WindowBlur {
                targetWindow: window
                blurEnabled: Settings.blurEnabled
                blurX: topBar.x
                blurY: topBar.y
                blurWidth: topBar.width
                blurHeight: topBar.height
                blurRadius: Settings.screenCornerRadius
            }

            // Top-anchored (not bottom) so the exclusive zone applies to the top
            // edge; full screen height for the pockets and frame
            anchors {
                left: true
                top: true
                right: true
            }
            implicitHeight: window.screen?.height ?? 0

            // Top Bar — content overlay only; chrome fill comes from PocketFrame's top border
            Item {
                id: topBar

                implicitHeight: Settings.barHeight
                width: window.screen?.width ?? 0
                height: Settings.barHeight
                y: -height * (1 - window.chromeReveal)
                anchors.left: parent.left
                anchors.right: parent.right
                visible: true
                z: 1

                Rectangle {
                    anchors.fill: parent
                    visible: !Settings.chromeShaderEnabled
                    color: Theme.withAlpha(Theme.surfaceBase, Settings.surfaceTransparency)
                }

                // Left - Workspaces
                Row {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.leftMargin: Settings.barContentMargin
                    spacing: Settings.barWorkspaceSpacing * 3

                    Row {
                        id: workspaces
                        anchors.verticalCenter: parent.verticalCenter
                        visible: Settings.showBarWorkspaces
                        spacing: Settings.barWorkspaceSpacing

                        Repeater {
                            model: Niri.workspaceModel

                            delegate: WorkspaceIndicator {
                                required property var modelData
                                visible: modelData.output === window.niriScreenName
                                workspace: modelData
                                isActive: modelData.isFocused
                            }
                        }
                    }

                    Pill {
                        anchors.verticalCenter: parent.verticalCenter
                        horizontalPadding: 12
                        // A single window needs no map
                        visible: Settings.showBarMinimap && minimap.tileCount > 1

                        WorkspaceMinimap {
                            id: minimap
                            outputName: window.niriScreenName
                            mapHeight: Settings.barPillHeight - 8
                        }
                    }
                }

                // Center - Window title
                Text {
                    id: title
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.leftMargin: Settings.barContentMargin
                    anchors.rightMargin: Settings.barContentMargin
                    visible: Settings.showBarTitle

                    text: root.sanitizeTitle(Niri.title)
                    textFormat: Text.PlainText
                    color: Theme.textPrimary
                    font.family: Settings.fontFamilyDefault
                    font.pixelSize: Settings.fontSizeBar

                    elide: Text.ElideRight
                    horizontalAlignment: Text.AlignHCenter
                }

                // Shared background for the right-side modules (Settings.barMergedPills)
                Pill {
                    anchors.fill: systemIndicators
                    visible: Settings.barMergedPills && systemIndicators.width > 0
                }

                // Right - System indicators
                RowLayout {
                    id: systemIndicators
                    spacing: Settings.barMergedPills ? 0 : Settings.barModuleSpacing
                    anchors.right: parent.right
                    anchors.rightMargin: Settings.barContentMargin
                    anchors.verticalCenter: parent.verticalCenter

                    // Volume pill
                    Pill {
                        flat: Settings.barMergedPills
                        visible: Settings.showBarVolume
                        VolumeIndicator {}
                    }

                    // Screen recording pill
                    Pill {
                        flat: Settings.barMergedPills
                        visible: Settings.showBarRecording
                        RecordingIndicator {}
                    }

                    // Headset battery pill
                    Pill {
                        flat: Settings.barMergedPills
                        visible: Settings.showBarHeadset
                        HeadsetBatteryIndicator {}
                    }

                    // Status pill
                    Pill {
                        flat: Settings.barMergedPills
                        visible: Settings.showBarResources
                        ResourceIndicator {}
                    }

                    // Date pill
                    Pill {
                        flat: Settings.barMergedPills
                        visible: Settings.showBarDate
                        clickable: true
                        onClicked: window.toggleCalendar()
                        DateIndicator {}
                    }

                    // Time pill
                    Pill {
                        flat: Settings.barMergedPills
                        visible: Settings.showBarTime
                        clickable: true
                        onClicked: window.toggleCalendar()
                        TimeIndicator {}
                    }
                }
            }

            // Rounded screen corners. Drawn here instead of a separate full-screen
            // overlay window per monitor (each window costs ~30 MB: own GL context,
            // render thread, buffers). Trade-off: hidden under fullscreen apps.
            Item {
                anchors.fill: parent
                z: 100
                opacity: window.chromeReveal

                Corner {
                    anchors.top: parent.top
                    anchors.left: parent.left
                    corner: 0
                    radius: Settings.screenCornerRadius
                    color: "black"
                }
                Corner {
                    anchors.top: parent.top
                    anchors.right: parent.right
                    corner: 1
                    radius: Settings.screenCornerRadius
                    color: "black"
                }
                Corner {
                    anchors.bottom: parent.bottom
                    anchors.right: parent.right
                    corner: 2
                    radius: Settings.screenCornerRadius
                    color: "black"
                }
                Corner {
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left
                    corner: 3
                    radius: Settings.screenCornerRadius
                    color: "black"
                }
            }

            PocketFrame {
                id: pocketFrame
                screenWidth: window.screen?.width ?? 0
                screenHeight: window.screen?.height ?? 0
                screenName: Niri.niriNameFor(window.screen?.name ?? "")
                z: -1
                opacity: window.chromeReveal
            }

            readonly property string screenName: Niri.niriNameFor(window.screen?.name ?? "")
            readonly property var panelState: {
                return screenName ? PanelStates.register(screenName) : null;
            }
            readonly property bool isFocusedScreen: {
                const focused = Niri.focused_output_name;
                return !!focused && focused === window.niriScreenName;
            }

            Item {
                id: notifWrapper
                anchors.top: parent.top
                anchors.right: parent.right
                anchors.topMargin: Settings.barHeight
                    + (window.panelState && window.panelState.calendar
                        ? (calendarPanel ? calendarPanel.height : 0) + 8
                        : 0)
                anchors.rightMargin: Settings.screenBorderWidth + (window.panelState && window.panelState.controlCenter ? controlCenterShift : 0)
                width: Settings.notificationWidth + Settings.screenBorderWidth + 50
                height: window.isFocusedScreen ? notifList.contentHeight : 0
                clip: true
                visible: window.isFocusedScreen

                readonly property int controlCenterShift: Settings.controlCenterWidth

                Behavior on anchors.rightMargin {
                    NumberAnimation {
                        duration: Settings.animationDurationMedium
                        easing.type: Easing.OutCubic
                    }
                }

                Behavior on anchors.topMargin {
                    NumberAnimation {
                        duration: Settings.animationDurationMedium
                        easing.type: Easing.OutCubic
                    }
                }

                Behavior on height {
                    enabled: height > 0
                    NumberAnimation { duration: 200; easing.type: Easing.OutQuad }
                }

                ListView {
                    id: notifList
                    anchors.fill: parent
                    model: window.isFocusedScreen ? NotificationModel.model : null
                    spacing: Settings.notificationItemSpacing
                    orientation: ListView.Vertical
                    interactive: false

                    delegate: Item {
                        required property var modelData
                        required property int index

                        readonly property bool keyboardFocused: NotificationKeyboard.popupKeyboardActive
                            && NotificationKeyboard.popupFocusIndex === index

                        width: notifList.width
                        height: notifCard.implicitHeight

                        Timer {
                            interval: Math.max(modelData.timeout || Settings.notificationTimeout, 3000)
                            running: window.isFocusedScreen
                            repeat: false
                            onTriggered: NotificationService.hidePopup(modelData.id, true)
                        }

                        Rectangle {
                            width: parent.width
                            height: parent.height
                            color: Settings.chromeShaderEnabled ? "transparent" : Theme.withAlpha(Theme.surfaceBase, Settings.surfaceTransparency)
                            radius: Settings.screenCornerRadius
                            border.width: parent.keyboardFocused ? 2 : 0
                            border.color: Theme.primary

                            NotificationCard {
                                id: notifCard
                                width: parent.width
                                notification: modelData
                                onActionInvoked: {
                                    // activate() already removed this id from the model
                                }
                                onCloseRequested: NotificationService.hidePopup(modelData.id, false)
                            }
                        }
                    }
                }
            }

            LauncherPanel {
                id: launcherPanel
                panelState: window.panelState
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                width: implicitWidth
            }

            OSDWrapper {
                id: osdPanel
                panelState: window.panelState
                screenName: window.screenName
            }

            // Built on first open, then kept: most panels are never opened on the
            // second monitor, and each costs 6–17 MB there. The wrapper fills the
            // window so the panel's x/y stay window-relative (PocketFrame, masks).
            Loader {
                id: wallpaperPanelLoader
                anchors.fill: parent
                z: 0
                readonly property bool wanted: window.panelState ? window.panelState.wallpaper : false
                property bool keep: false
                // Latch outside the active binding (loading inside it is synchronous)
                onWantedChanged: if (wanted) keep = true
                Component.onCompleted: if (wanted) keep = true
                active: keep
                sourceComponent: Item {
                    property alias panel: inner
                    WallpaperPanel {
                        id: inner
                        panelState: window.panelState
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottom: parent.bottom
                    }
                }
            }
            readonly property Item wallpaperPanel: wallpaperPanelLoader.item ? wallpaperPanelLoader.item.panel : null

            // Built on first open, then kept: most panels are never opened on the
            // second monitor, and each costs 6–17 MB there. The wrapper fills the
            // window so the panel's x/y stay window-relative (PocketFrame, masks).
            Loader {
                id: controlCenterPanelLoader
                anchors.fill: parent
                z: 1
                readonly property bool wanted: window.panelState ? window.panelState.controlCenter : false
                property bool keep: false
                // Latch outside the active binding (loading inside it is synchronous)
                onWantedChanged: if (wanted) keep = true
                Component.onCompleted: if (wanted) keep = true
                active: keep
                sourceComponent: Item {
                    property alias panel: inner
                    ControlCenterPanel {
                        id: inner
                        panelState: window.panelState
                        screenName: window.screenName
                        screenWidth: window.screen?.width ?? 0
                        screenHeight: window.screen?.height ?? 0
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        anchors.right: parent.right
                        anchors.topMargin: Settings.barHeight
                        anchors.bottomMargin: Settings.screenBorderWidth
                        anchors.rightMargin: Settings.screenBorderWidth
                    }
                }
            }
            readonly property Item controlCenterPanel: controlCenterPanelLoader.item ? controlCenterPanelLoader.item.panel : null

            // Built on first open, then kept: most panels are never opened on the
            // second monitor, and each costs 6–17 MB there. The wrapper fills the
            // window so the panel's x/y stay window-relative (PocketFrame, masks).
            Loader {
                id: settingsPanelLoader
                anchors.fill: parent
                z: 2
                readonly property bool wanted: window.panelState ? window.panelState.settings : false
                property bool keep: false
                // Latch outside the active binding (loading inside it is synchronous)
                onWantedChanged: if (wanted) keep = true
                Component.onCompleted: if (wanted) keep = true
                active: keep
                sourceComponent: Item {
                    property alias panel: inner
                    SettingsPanel {
                        id: inner
                        panelState: window.panelState
                        screenName: window.screenName
                        screenWidth: window.screen?.width ?? 0
                        screenHeight: window.screen?.height ?? 0
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.top: parent.top
                        anchors.topMargin: Settings.barHeight
                    }
                }
            }
            readonly property Item settingsPanel: settingsPanelLoader.item ? settingsPanelLoader.item.panel : null

            // Built on first open, then kept: most panels are never opened on the
            // second monitor, and each costs 6–17 MB there. The wrapper fills the
            // window so the panel's x/y stay window-relative (PocketFrame, masks).
            Loader {
                id: calendarPanelLoader
                anchors.fill: parent
                z: 2
                readonly property bool wanted: window.panelState ? window.panelState.calendar : false
                property bool keep: false
                // Latch outside the active binding (loading inside it is synchronous)
                onWantedChanged: if (wanted) keep = true
                Component.onCompleted: if (wanted) keep = true
                active: keep
                sourceComponent: Item {
                    property alias panel: inner
                    CalendarPanel {
                        id: inner
                        panelState: window.panelState
                        anchors.top: parent.top
                        anchors.right: parent.right
                        anchors.topMargin: Settings.barHeight
                        anchors.rightMargin: Settings.screenBorderWidth + Settings.barContentMargin
                    }
                }
            }
            readonly property Item calendarPanel: calendarPanelLoader.item ? calendarPanelLoader.item.panel : null

            Component.onCompleted: {
                pocketFrame.notifWrapper = notifWrapper;
                pocketFrame.launcherPanel = launcherPanel;
                pocketFrame.osdPanel = osdPanel;
                // Lazy panels: bind, they appear on first open
                pocketFrame.wallpaperPanel = Qt.binding(() => window.wallpaperPanel);
                pocketFrame.controlCenterPanel = Qt.binding(() => window.controlCenterPanel);
                pocketFrame.settingsPanel = Qt.binding(() => window.settingsPanel);
                pocketFrame.calendarPanel = Qt.binding(() => window.calendarPanel);
            }

            Rectangle {
                id: innerClickThrough
                anchors {
                    fill: parent
                    topMargin: Settings.barHeight
                    leftMargin: Settings.screenBorderWidth
                    rightMargin: Settings.screenBorderWidth
                        + (window.panelState && window.panelState.controlCenter
                            ? Settings.controlCenterWidth
                            : 0)
                    bottomMargin: {
                        let m = Settings.screenBorderWidth;
                        if (window.panelState && window.panelState.launcher && launcherPanel.pocketActive)
                            m += launcherPanel.blobH;
                        else if (window.panelState && window.panelState.wallpaper && wallpaperPanel && wallpaperPanel.pocketActive)
                            m += wallpaperPanel.blobH;
                        return m;
                    }
                }
                visible: false
            }

            // Hit targets for popups that live inside the click-through hole
            Item {
                id: notifHitRegion
                x: notifWrapper.x
                y: notifWrapper.y
                width: notifWrapper.height > 0 ? notifWrapper.width : 0
                height: notifWrapper.height > 0 ? notifWrapper.height : 0
            }

            Item {
                id: osdHitRegion
                x: osdPanel.visualX
                y: osdPanel.visualY
                width: osdPanel.pocketActive ? osdPanel.visualW : 0
                height: osdPanel.pocketActive ? osdPanel.visualH : 0
            }

            Item {
                id: settingsHitRegion
                x: settingsPanel ? settingsPanel.visualX : 0
                y: settingsPanel ? settingsPanel.visualY : 0
                width: settingsPanel && settingsPanel.pocketActive ? settingsPanel.visualW : 0
                height: settingsPanel && settingsPanel.pocketActive ? settingsPanel.visualH : 0
            }

            Item {
                id: calendarHitRegion
                x: calendarPanel ? calendarPanel.visualX : 0
                y: calendarPanel ? calendarPanel.visualY : 0
                width: calendarPanel && calendarPanel.pocketActive ? calendarPanel.visualW : 0
                height: calendarPanel && calendarPanel.pocketActive ? calendarPanel.visualH : 0
            }

            Item {
                id: wallpaperHitRegion
                x: wallpaperPanel ? wallpaperPanel.visualX : 0
                y: wallpaperPanel ? wallpaperPanel.visualY : 0
                width: wallpaperPanel && wallpaperPanel.pocketActive ? wallpaperPanel.visualW : 0
                height: wallpaperPanel && wallpaperPanel.pocketActive ? wallpaperPanel.visualH : 0
            }

            // Input on chrome (Xor hole), then add popup hit regions back
            mask: Region {
                item: innerClickThrough
                intersection: Intersection.Xor

                Region {
                    item: notifHitRegion
                    intersection: Intersection.Subtract
                }

                Region {
                    item: osdHitRegion
                    intersection: Intersection.Subtract
                }

                Region {
                    item: settingsHitRegion
                    intersection: Intersection.Subtract
                }

                Region {
                    item: calendarHitRegion
                    intersection: Intersection.Subtract
                }

                Region {
                    item: wallpaperHitRegion
                    intersection: Intersection.Subtract
                }
            }
        }
    }
}
