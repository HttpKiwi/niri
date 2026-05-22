pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pipewire
import Caelestia.Blobs
import qs.config
import qs.core
import qs.components.base
import qs.components.indicators

Item {
    id: root

    required property ShellScreen screen

    readonly property real bt: Settings.screenBorderWidth
    readonly property real bh: Settings.barHeight
    readonly property real cr: Settings.screenCornerRadius
    readonly property real bm: 50

    property bool showLauncher: false
    property bool showOSD: false
    property bool showWallpaper: false

    property Item launcherPanelItem: null
    property Item osdPanelItem: null
    property Item notifPanelItem: null
    property Item wallpaperPanelItem: null

    PanelWindow {
        id: win

        screen: root.screen
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        exclusiveZone: 0
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.namespace: "quickshell:shell"
        WlrLayershell.keyboardFocus: root.showLauncher ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

        anchors.top: true
        anchors.bottom: true
        anchors.left: true
        anchors.right: true

        mask: Region {
            x: root.bh
            y: root.bh
            width: win.width - root.bh - root.bt
            height: win.height - root.bh - root.bt
            intersection: Intersection.Xor

            Region {
                x: root.launcherPanelItem?.x ?? 0
                y: (root.launcherPanelItem?.y ?? 0) + root.bh
                width: root.launcherPanelItem?.width ?? 0
                height: root.launcherPanelItem?.height ?? 0
                intersection: Intersection.Subtract
            }

            Region {
                x: root.osdPanelItem?.x ?? 0
                y: (root.osdPanelItem?.y ?? 0) + root.bh
                width: root.osdPanelItem?.width ?? 0
                height: root.osdPanelItem?.height ?? 0
                intersection: Intersection.Subtract
            }

            Region {
                x: root.notifPanelItem?.x ?? 0
                y: (root.notifPanelItem?.y ?? 0) + root.bh
                width: root.notifPanelItem?.width ?? 0
                height: root.notifPanelItem?.height ?? 0
                intersection: Intersection.Subtract
            }

            Region {
                x: root.wallpaperPanelItem?.x ?? 0
                y: (root.wallpaperPanelItem?.y ?? 0) + root.bh
                width: root.wallpaperPanelItem?.width ?? 0
                height: root.wallpaperPanelItem?.height ?? 0
                intersection: Intersection.Subtract
            }
        }

        Item {
            anchors.fill: parent
            anchors.margins: -root.bm

            layer.enabled: true
            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowColor: Qt.rgba(0, 0, 0, 0.45)
                blurMax: 16
            }

            BlobGroup {
                id: blobGroup
                color: Theme.surfaceBase
                smoothing: Settings.screenSmoothing
            }

            BlobInvertedRect {
                anchors.fill: parent
                group: blobGroup
                radius: root.cr
                borderTop: root.bh + root.bm
                borderLeft: root.bt + root.bm
                borderRight: root.bt + root.bm
                borderBottom: root.bt + root.bm
            }

            BlobRect {
                group: blobGroup
                x: root.launcherPanelItem ? root.launcherPanelItem.x + root.bm : 0
                y: root.launcherPanelItem ? root.launcherPanelItem.y + root.bh + root.bm : 0
                implicitWidth: root.launcherPanelItem ? root.launcherPanelItem.width : 0
                implicitHeight: root.launcherPanelItem ? root.launcherPanelItem.height : 0
                radius: root.cr
                deformScale: 0.00001
                stiffness: 200
                damping: 60
            }

            BlobRect {
                group: blobGroup
                x: root.osdPanelItem ? root.osdPanelItem.x + root.bm : 0
                y: root.osdPanelItem ? root.osdPanelItem.y + root.bh + root.bm : 0
                implicitWidth: root.osdPanelItem ? root.osdPanelItem.width : 0
                implicitHeight: root.osdPanelItem ? root.osdPanelItem.height : 0
                radius: root.cr
                deformScale: 0.00001
                stiffness: 200
                damping: 60
            }

            BlobRect {
                group: blobGroup
                x: root.notifPanelItem ? root.notifPanelItem.x + root.bm : 0
                y: root.notifPanelItem ? root.notifPanelItem.y + root.bh + root.bm : 0
                implicitWidth: root.notifPanelItem ? root.notifPanelItem.width : 0
                implicitHeight: root.notifPanelItem ? root.notifPanelItem.height : 0
                radius: root.cr
                deformScale: 0.00001
                stiffness: 200
                damping: 60
            }

            BlobRect {
                group: blobGroup
                x: root.wallpaperPanelItem ? root.wallpaperPanelItem.x + root.bm : 0
                y: root.wallpaperPanelItem ? root.wallpaperPanelItem.y + root.bh + root.bm : 0
                implicitWidth: root.wallpaperPanelItem ? root.wallpaperPanelItem.width : 0
                implicitHeight: root.wallpaperPanelItem ? root.wallpaperPanelItem.height : 0
                radius: root.cr
                deformScale: 0.00001
                stiffness: 200
                damping: 60
            }
        }

        Rectangle {
            id: topBar
            height: root.bh
            width: parent.width
            anchors.top: parent.top
            color: Theme.surfaceBase

            Row {
                anchors.left: parent.left
                anchors.leftMargin: Settings.barContentMargin
                anchors.verticalCenter: parent.verticalCenter
                spacing: Settings.barWorkspaceSpacing

                Repeater {
                    model: {
                        var name = root.screen?.name ?? ""
                        return name ? (Niri.workspaces_by_monitor[name] || Niri.workspaces || []) : (Niri.workspaces || [])
                    }

                    delegate: WorkspaceIndicator {
                        required property var modelData
                        workspace: modelData
                        isActive: modelData.is_focused
                    }
                }
            }

            Text {
                anchors.centerIn: parent
                text: Niri.title
                color: Theme.textPrimary
                font.pixelSize: Settings.fontSizeLarge
                elide: Text.ElideRight
                horizontalAlignment: Text.AlignHCenter
            }

            RowLayout {
                anchors.right: parent.right
                anchors.rightMargin: Settings.barContentMargin
                anchors.verticalCenter: parent.verticalCenter
                spacing: Settings.barModuleSpacing

                Pill { VolumeIndicator {} }
                Pill { HeadsetBatteryIndicator {} }
                Pill { ResourceIndicator {} }
                Pill { DateIndicator {} }
                Pill { TimeIndicator {} }
            }
        }

        Item {
            id: panelArea
            anchors.top: topBar.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom

            Item {
                id: launcherContainer
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                width: implicitWidth
                height: implicitHeight
                implicitWidth: 500
                implicitHeight: root.showLauncher ? 400 : 0
                clip: true

                Behavior on implicitHeight { NumberAnimation { duration: 200; easing.type: Easing.OutQuad } }

                Rectangle {
                    anchors.fill: parent
                    color: Theme.surfaceBase
                    radius: root.cr
                }

                Component.onCompleted: root.launcherPanelItem = this
            }

            Item {
                id: osdContainer
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 80
                width: implicitWidth
                height: implicitHeight
                implicitWidth: root.showOSD ? Settings.osdWidth : 0
                implicitHeight: 60
                clip: true

                Behavior on implicitWidth { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }

                Rectangle {
                    anchors.fill: parent
                    color: Theme.surfaceBase
                    radius: root.cr

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 12

                        Text {
                            text: Math.round(Pipewire.defaultAudioSink?.volume * 100) + "%"
                            color: Theme.textPrimary
                            font.pixelSize: 20
                            font.bold: true
                        }

                        Rectangle {
                            width: 150
                            height: 8
                            radius: 4
                            color: Theme.surfaceBase

                            Rectangle {
                                width: parent.width * (Pipewire.defaultAudioSink?.volume ?? 0)
                                height: parent.height
                                radius: 4
                                color: Theme.accent
                            }
                        }

                        Text {
                            text: Pipewire.defaultAudioSink?.muted ? "MUTED" : ""
                            color: Theme.textSecondary
                            font.pixelSize: 14
                        }
                    }
                }

                Component.onCompleted: root.osdPanelItem = this
            }

            Item {
                id: notifContainer
                anchors.top: parent.top
                anchors.right: parent.right
                anchors.topMargin: 10
                width: implicitWidth
                height: implicitHeight
                implicitWidth: 0
                implicitHeight: 0

                Component.onCompleted: root.notifPanelItem = this
            }

            Item {
                id: wallpaperContainer
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 50
                width: implicitWidth
                height: implicitHeight
                implicitWidth: root.showWallpaper ? 1200 : 0
                implicitHeight: root.showWallpaper ? 300 : 0
                clip: true

                Behavior on implicitHeight { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                Behavior on implicitWidth { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }

                Rectangle {
                    anchors.fill: parent
                    color: Theme.surfaceBase
                    radius: root.cr
                }

                Component.onCompleted: root.wallpaperPanelItem = this
            }
        }
    }

    IpcHandler {
        target: "launcher"
        function toggleLauncher() {
            root.showLauncher = !root.showLauncher
        }
    }

    IpcHandler {
        target: "wallpaperSelector"
        function toggleSelector() {
            root.showWallpaper = !root.showWallpaper
        }
    }
}
