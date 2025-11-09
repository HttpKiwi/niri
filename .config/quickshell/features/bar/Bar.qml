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

/**
 * Bar - Single PanelWindow combining bar and screen border
 * Creates a horizontal top bar with screen borders and rounded corners
 * Automatically handles multiple monitors via Variants
 */
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
            WlrLayershell.namespace: "quickshell:bar"
            visible: !Niri.is_overview

            screen: modelData || Quickshell.screens[0]

            anchors {
                left: true
                top: true
                right: true
                bottom: true
            }

            // Inline Components
            component Corner: WrapperItem {
                id: cornerRoot

                property int corner
                property real radius: 18
                property color color

                Component.onCompleted: {
                    switch (corner) {
                    case 0: // topLeft
                        anchors.left = parent.left
                        anchors.top = parent.top
                        break
                    case 1: // topRight
                        anchors.top = parent.top
                        anchors.right = parent.right
                        rotation = 90
                        break
                    }
                }

                Shape {
                    preferredRendererType: Shape.CurveRenderer

                    ShapePath {
                        strokeWidth: 0
                        fillColor: cornerRoot.color
                        startX: cornerRoot.radius

                        PathArc {
                            relativeX: -cornerRoot.radius
                            relativeY: cornerRoot.radius
                            radiusX: cornerRoot.radius
                            radiusY: radiusX
                            direction: PathArc.Counterclockwise
                        }

                        PathLine {
                            relativeX: 0
                            relativeY: -cornerRoot.radius
                        }

                        PathLine {
                            relativeX: cornerRoot.radius
                            relativeY: 0
                        }
                    }
                }
            }

            component Exclusion: PanelWindow {
                property string name
                implicitWidth: 0
                implicitHeight: 0
                WlrLayershell.namespace: `quickshell:${name}ExclusionZone`
            }

            // Exclusion Zone for top bar
            Exclusion {
                name: "top"
                exclusiveZone: topBar.implicitHeight
                anchors.top: true
                screen: window.screen
            }

            // Top Bar
            Rectangle {
                id: topBar

                implicitWidth: window.screen?.width ?? 0
                implicitHeight: Settings.barHeight
                color: Theme.surfaceBase
                anchors.top: parent.top
                visible: !Niri.is_overview

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

            // Rounded bottom corners of the bar (where bar meets screen borders)
            RoundCorner {
                id: barBottomLeftCorner
                anchors.top: topBar.bottom
                anchors.left: parent.left
                size: 18
                corner: barBottomLeftCorner.cornerEnum.topLeft
                color: Theme.surfaceBase
                visible: !Niri.is_overview
            }

            RoundCorner {
                id: barBottomRightCorner
                anchors.top: topBar.bottom
                anchors.right: parent.right
                size: 18
                corner: barBottomRightCorner.cornerEnum.topRight
                color: Theme.surfaceBase
                visible: !Niri.is_overview
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
            RoundCorner {
                id: bottomLeftCorner
                corner: bottomLeftCorner.cornerEnum.bottomLeft
                size: 18
                color: Color.background
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.leftMargin: 6
                anchors.bottomMargin: 6
                visible: !Niri.is_overview
            }

            RoundCorner {
                id: bottomRightCorner
                corner: bottomRightCorner.cornerEnum.bottomRight
                size: 18
                color: Color.background
                anchors.bottom: parent.bottom
                anchors.right: parent.right
                anchors.rightMargin: 6
                anchors.bottomMargin: 6
                visible: !Niri.is_overview
            }

            // Top rounded corners area (for masking and corner rendering)
            Rectangle {
                id: cornersArea
                width: (window.screen?.width ?? 0)
                height: topBar.implicitHeight
                color: "transparent"
                x: 0
                y: 0

                // Top-left corner
                Corner {
                    corner: 0
                    radius: 18
                    color: Theme.surfaceBase
                }

                // Top-right corner
                Corner {
                    corner: 1
                    radius: 18
                    color: Theme.surfaceBase
                }
            }

            // Inner rectangle that represents the click-through area
            // Everything OUTSIDE this (the bar and borders) will be interactive
            // Using Xor intersection to invert the mask
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

            // Mask with Xor: Makes everything EXCEPT innerClickThrough interactive
            // This inverts the mask so bar + borders are interactive, center is click-through
            mask: Region {
                item: innerClickThrough
                intersection: Intersection.Xor
            }
        }
    }
}

