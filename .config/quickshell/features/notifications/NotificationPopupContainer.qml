pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import qs.core
import qs.config
import qs.components.base

/**
 * NotificationPopupContainer - Container for notification popup windows
 * Displays active notifications stacked at top-right of screen
 */
PanelWindow {
    id: root

    screen: Quickshell.screens.find(s => s.name === Niri.focused_output_name) ?? Quickshell.primaryScreen
    visible: NotificationModel.count() > 0
    color: "transparent"
    exclusiveZone: -1

    WlrLayershell.namespace: "quickshell:notificationPopup"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    WindowBlur {
        targetWindow: root
        blurEnabled: Settings.blurEnabled
        blurRadius: Settings.cardRadius
    }

    anchors {
        top: true
        right: true
    }

    margins {
        top: Settings.notificationTopMargin
        right: Settings.notificationRightMargin
    }

    implicitWidth: Settings.notificationWidth
    implicitHeight: Math.min(column.contentHeight, screen ? screen.height * 0.6 : 600)

    mask: Region {
        item: column
    }

    Column {
        id: column
        anchors.fill: parent
        spacing: 8

        Repeater {
            model: NotificationModel.model

            delegate: NotificationItem {
                required property var modelData
                required property int index

                notificationData: modelData
                y: index * (Settings.notificationHeight + 8)

                onExitFinished: {
                    NotificationModel.remove(index)
                }
            }
        }
    }

    // Remove notifications that have exited
    Connections {
        target: NotificationModel.model
        function onCountChanged() {
            // Model count changed, items handle their own exit
        }
    }
}
