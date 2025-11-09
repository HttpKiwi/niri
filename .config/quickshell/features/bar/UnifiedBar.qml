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
            visible: !Niri.is_overview

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
                color: Theme.surfaceBase
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                visible: !Niri.is_overview
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

                    text: Niri.title
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

            Corner {
                id: barBottomLeftCorner
                anchors.top: topBar.bottom
                anchors.left: parent.left
                corner: 0  // topLeft shape, positioned to create bar-to-border transition
                radius: 24
                color: Theme.surfaceBase
            }

            Corner {
                id: barBottomRightCorner
                anchors.top: topBar.bottom
                anchors.right: parent.right
                corner: 1  // topRight shape, positioned to create bar-to-border transition
                radius: 24
                color: Theme.surfaceBase
            }

            // Screen Borders
            // Left border
            Rectangle {
                id: leftBorder
                width: 6
                height: (window.screen?.height ?? 0) - topBar.implicitHeight
                color: Color.background
                anchors.left: parent.left
                anchors.top: topBar.bottom
                visible: !Niri.is_overview
            }

            // Right border
            Rectangle {
                id: rightBorder
                width: 6
                height: (window.screen?.height ?? 0) - topBar.implicitHeight
                color: Color.background
                anchors.right: parent.right
                anchors.top: topBar.bottom
                visible: !Niri.is_overview
            }

            // Bottom border
            Rectangle {
                id: bottomBorder
                width: (window.screen?.width ?? 0) - (leftBorder.width + rightBorder.width)
                height: 6
                color: Color.background
                anchors.left: leftBorder.right
                anchors.bottom: parent.bottom
                visible: !Niri.is_overview
            }

            // Bottom rounded corners
            Corner {
                id: bottomLeftCorner
                corner: 3  // bottomLeft
                radius: 16
                color: Color.background
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.leftMargin: 6
                anchors.bottomMargin: 6
            }

            Corner {
                id: bottomRightCorner
                corner: 2  // bottomRight
                radius: 16
                color: Color.background
                anchors.bottom: parent.bottom
                anchors.right: parent.right
                anchors.rightMargin: 6
                anchors.bottomMargin: 6
            }


            Rectangle {
                id: innerClickThrough
                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                    bottom: parent.bottom
                    leftMargin: 6
                    rightMargin: 6
                    topMargin: topBar.implicitHeight
                    bottomMargin: 6
                }
                color: "transparent"
                visible: false
            }

            mask: Region {
                item: innerClickThrough
                intersection: Intersection.Xor
            }
        }
    }
}

