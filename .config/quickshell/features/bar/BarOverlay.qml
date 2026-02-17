pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.config
import qs.core
import qs.components.base
import qs.components.indicators

/**
 * BarOverlay - Bar content overlay
 * Contains workspaces, window title, and system indicators
 * Positioned on top of the Frame's thick bar area
 */
Item {
    id: overlayRoot

    // Required: screen reference for workspace filtering
    required property var targetScreen

    function sanitizeTitle(s) {
        if (!s || typeof s !== "string") return s || ""
        return s.replace(/[^\x20-\x7e\xa0-\xff]/g, "")
    }

    // Dimensions
    property real barHeight: Settings.barHeight

    // Fill width, fixed height
    height: barHeight

    // Left - Workspaces
    Row {
        id: workspaces
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: Settings.barContentMargin
        spacing: Settings.barWorkspaceSpacing

        Repeater {
            id: wsRepeater

            model: {
                const screenName = overlayRoot.targetScreen?.name || ""
                if (screenName) {
                    const ws = Niri.workspaces_by_monitor[screenName]
                    return ws ? ws.length : 0
                }
                return Niri.workspaces ? Niri.workspaces.length : 0
            }

            delegate: WorkspaceIndicator {
                required property int index

                workspace: {
                    const screenName = overlayRoot.targetScreen?.name || ""
                    if (screenName) {
                        const ws = Niri.workspaces_by_monitor[screenName]
                        return ws ? ws[index] : {}
                    }
                    return Niri.workspaces ? Niri.workspaces[index] : {}
                }

                isActive: workspace.is_active || false
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

        text: overlayRoot.sanitizeTitle(Niri.title)
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

        Pill {
            VolumeIndicator {}
        }

        Pill {
            ResourceIndicator {}
        }

        Pill {
            DateIndicator {}
        }

        Pill {
            TimeIndicator {}
        }
    }
}
