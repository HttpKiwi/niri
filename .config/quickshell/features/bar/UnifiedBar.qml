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
            WlrLayershell.keyboardFocus: window.panelState && window.panelState.launcher ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
            visible: true

            screen: modelData || Quickshell.screens[0]

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

            // Top Bar
            Rectangle {
                id: topBar

                implicitHeight: Settings.barHeight
                width: window.screen?.width ?? 0
                height: Settings.barHeight
                color: "transparent"
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                visible: true
                z: 0  // Explicitly set z to ensure corners can be above

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
                        model: {
                            try {
                                if (window.targetMonitor) {
                                    const workspaces = Niri.getWorkspacesForMonitor(window.targetMonitor)
                                    return workspaces || []
                                } else {
                                    // Try to get monitor name from screen
                                    const screenName = window.screen?.name || ""
                                    if (screenName) {
                                        const workspaces = Niri.getWorkspacesForMonitor(screenName)
                                        return workspaces || []
                                    }
                                    return Niri.workspaces || []
                                }
                            } catch (e) {
                                console.warn("Error getting workspaces:", e)
                                return []
                            }
                        }

                        delegate: WorkspaceIndicator {
                            required property var modelData
                            workspace: modelData
                            isActive: {
                                if (window.targetMonitor || window.screen?.name) {
                                    const monitorName = window.targetMonitor || window.screen?.name
                                    return modelData.idx === Niri.focused_workspace_idx &&
                                           modelData.output === monitorName
                                }
                                return modelData.is_focused
    }
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
                anchors.rightMargin: Settings.screenBorderWidth
                width: Settings.notificationWidth + Settings.screenBorderWidth + 50
                height: notifList.count * Settings.notificationSpacing + (notifList.count > 0 ? Settings.notificationHeight - Settings.notificationSpacing : 0)
                clip: true

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
                            onTriggered: NotificationModel.model.remove(index)
                        }

                        Rectangle {
                            anchors.fill: parent
                            color: Theme.surfaceBase
                            radius: Settings.screenCornerRadius

                            NotificationCard {
                                anchors.fill: parent
                                anchors.margins: 0
                                notification: {
                                    "summary": modelData.summary,
                                    "body": modelData.body,
                                    "appName": modelData.appName,
                                    "appIcon": modelData.appIcon,
                                    "image": modelData.image
                                }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            acceptedButtons: Qt.LeftButton
                            onClicked: NotificationModel.model.remove(index)
                        }
                    }
                }
            }

            readonly property var panelState: {
                const niriName = Niri.niriNameFor(window.screen?.name ?? "");
                return niriName ? PanelStates.register(niriName) : null;
            }

            LauncherPanel {
                id: launcherPanel
                panelState: window.panelState
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                width: 500
            }

            Component.onCompleted: {
                pocketFrame.notifWrapper = notifWrapper;
                pocketFrame.launcherPanel = launcherPanel;
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
                    bottomMargin: window.panelState && window.panelState.launcher ? Settings.screenBorderWidth + launcherPanel.height : Settings.screenBorderWidth
                }
                visible: false
            }

            mask: Region {
                item: innerClickThrough
                intersection: Intersection.Xor
            }
        }
    }
}
