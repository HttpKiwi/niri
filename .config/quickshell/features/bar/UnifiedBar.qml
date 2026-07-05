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

            property var modelData
            property string targetMonitor: ""

            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            exclusiveZone: 0
            WlrLayershell.layer: WlrLayer.Top
            WlrLayershell.namespace: "quickshell:unifiedBar"
            WlrLayershell.keyboardFocus: window.panelState && (window.panelState.launcher || window.panelState.wallpaper || window.panelState.historyPanel) ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
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

            anchors {
                left: true
                top: true
                right: true
                bottom: true
            }

            // Inline Components
            component Exclusion: PanelWindow {
                property string name
                implicitWidth: 0
                implicitHeight: 0
                WlrLayershell.namespace: `quickshell:${name}ExclusionZone`
            }

            // Exclusion Zone for top bar
            Exclusion {
                name: "top"
                exclusiveZone: topBar.implicitHeight - 5
                anchors.top: true
                screen: window.screen
            }

            // Top Bar — content overlay only; chrome fill comes from PocketFrame's top border
            Item {
                id: topBar

                implicitHeight: Settings.barHeight
                width: window.screen?.width ?? 0
                height: Settings.barHeight
                anchors.top: parent.top
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
                    spacing: Settings.barWorkspaceSpacing

                    Row {
                        id: workspaces
                        spacing: Settings.barWorkspaceSpacing

                        Repeater {
                        model: Niri.workspaceModel

                        delegate: WorkspaceIndicator {
                            required property var modelData
                            visible: modelData.output === (window.targetMonitor || window.screen?.name || "")
                            workspace: modelData
                            isActive: modelData.isFocused
                        }
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

                    text: root.sanitizeTitle(Niri.title)
                    textFormat: Text.PlainText
                    color: Theme.textPrimary
                    font.pixelSize: Settings.fontSizeLarge

                    elide: Text.ElideRight
                    horizontalAlignment: Text.AlignHCenter
                }

                // Right - System indicators
                RowLayout {
                    id: systemIndicators
                    spacing: Settings.barModuleSpacing
                    anchors.right: parent.right
                    anchors.rightMargin: Settings.barContentMargin
                    anchors.verticalCenter: parent.verticalCenter

                    // Volume pill
                    Pill {
                        VolumeIndicator {}
                    }

                    // Headset battery pill
                    Pill {
                        HeadsetBatteryIndicator {}
                    }

                    // Status pill
                    Pill {
                        ResourceIndicator {}
                    }

                    // Date pill
                    Pill {
                        DateIndicator {}
                    }

                    // Time pill
                    Pill {
                        TimeIndicator {}
                    }
                }
            }

            PocketFrame {
                id: pocketFrame
                screenWidth: window.screen?.width ?? 0
                screenHeight: window.screen?.height ?? 0
                screenName: Niri.niriNameFor(window.screen?.name ?? "")
                z: -1
            }

            Item {
                id: notifWrapper
                anchors.top: parent.top
                anchors.right: parent.right
                anchors.topMargin: Settings.barHeight
                anchors.rightMargin: Settings.screenBorderWidth + (window.panelState && window.panelState.historyPanel ? historyPanelShift : 0)
                width: Settings.notificationWidth + Settings.screenBorderWidth + 50
                height: notifList.count * Settings.notificationSpacing + (notifList.count > 0 ? Settings.notificationHeight - Settings.notificationSpacing : 0)
                clip: true

                readonly property int historyPanelShift: Settings.controlCenterWidth

                Behavior on anchors.rightMargin {
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
                    model: NotificationModel.model
                    spacing: Settings.notificationSpacing - Settings.notificationHeight
                    orientation: ListView.Vertical
                    interactive: false

                    delegate: Item {
                        required property var modelData
                        required property int index

                        width: notifList.width
                        height: Settings.notificationHeight
                        clip: true

                        Timer {
                            interval: Math.max(modelData.timeout || Settings.notificationTimeout, 3000)
                            running: true
                            repeat: false
                            onTriggered: NotificationService.hidePopup(modelData.id, true)
                        }

                        Rectangle {
                            anchors.fill: parent
                            color: Settings.chromeShaderEnabled ? "transparent" : Theme.withAlpha(Theme.surfaceBase, Settings.surfaceTransparency)
                            radius: Settings.screenCornerRadius

                            NotificationCard {
                                anchors.fill: parent
                                anchors.margins: 0
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

            readonly property string screenName: Niri.niriNameFor(window.screen?.name ?? "")
            readonly property var panelState: {
                return screenName ? PanelStates.register(screenName) : null;
            }

            LauncherPanel {
                id: launcherPanel
                panelState: window.panelState
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                width: 500
            }

            OSDWrapper {
                id: osdPanel
                panelState: window.panelState
                screenName: window.screenName
            }

            WallpaperPanel {
                id: wallpaperPanel
                panelState: window.panelState
            }

            ControlCenterPanel {
                id: controlCenterPanel
                panelState: window.panelState
                screenName: window.screenName
                screenWidth: window.screen?.width ?? 0
                screenHeight: window.screen?.height ?? 0
                z: 1
            }

            Component.onCompleted: {
                pocketFrame.notifWrapper = notifWrapper;
                pocketFrame.launcherPanel = launcherPanel;
                pocketFrame.osdPanel = osdPanel;
                pocketFrame.wallpaperPanel = wallpaperPanel;
                pocketFrame.controlCenterPanel = controlCenterPanel;
                const niriName = Niri.niriNameFor(window.screen?.name ?? "");
                if (niriName) {
                    PopupRegistry.notifWrappers[niriName] = notifWrapper;
                }
            }

            Rectangle {
                id: innerClickThrough
                anchors {
                    fill: parent
                    topMargin: Settings.barHeight
                    leftMargin: Settings.screenBorderWidth
                    rightMargin: Settings.screenBorderWidth
                        + (window.panelState && window.panelState.historyPanel
                            ? Settings.controlCenterWidth
                            : 0)
                    bottomMargin: window.panelState && window.panelState.launcher ? Settings.screenBorderWidth + launcherPanel.height : Settings.screenBorderWidth
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
            }
        }
    }
}
