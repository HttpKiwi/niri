pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import Quickshell
import Quickshell.Widgets
import Quickshell.Wayland
import qs.core
import qs.config
import qs.components.base
import qs.components.indicators
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

            property var modelData
            property string targetMonitor: ""

            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            exclusiveZone: 0
            WlrLayershell.layer: WlrLayer.Top
            WlrLayershell.namespace: "quickshell:unifiedBar"
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
                    id: workspaces
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.leftMargin: Settings.barContentMargin
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

            Frame {
                id: frame
                screenWidth: window.screen?.width ?? 0
                screenHeight: window.screen?.height ?? 0
                z: -1
            }

            Rectangle {
                id: innerClickThrough
                anchors {
                    fill: parent
                    topMargin: Settings.barHeight
                    leftMargin: Settings.screenBorderWidth
                    rightMargin: Settings.screenBorderWidth
                    bottomMargin: Settings.screenBorderWidth
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

