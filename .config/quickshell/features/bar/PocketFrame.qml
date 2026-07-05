pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import Caelestia.Blobs
import qs.config
import qs.core

Item {
    id: frameRoot

    required property real screenWidth
    required property real screenHeight
    property string screenName: ""
    property Item notifWrapper: null
    property Item launcherPanel: null
    property Item osdPanel: null
    property Item wallpaperPanel: null
    property Item controlCenterPanel: null
    readonly property real blobMargin: 50
    readonly property real borderTop: Settings.barHeight + blobMargin
    readonly property real borderSide: Settings.screenBorderWidth + blobMargin
    readonly property real borderBottom: Settings.screenBorderWidth + blobMargin

    width: screenWidth
    height: screenHeight

    Item {
        id: shadowLayer
        anchors.fill: parent
        anchors.margins: -blobMargin

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
            proceduralEnabled: Settings.chromeShaderEnabled
            chromeTime: ChromeClock.time
            chromeScreenWidth: frameRoot.screenWidth
            chromeScreenHeight: frameRoot.screenHeight
            chromeOriginX: frameRoot.blobMargin
            chromeOriginY: frameRoot.blobMargin
            cellSize: Settings.chromeCellSize
            dotSize: Settings.chromeDotSize
            animSpeed: Settings.chromeAnimSpeed
            intensity: Settings.chromeIntensity
            // Saturated matugen accents (Theme.color props, not string lookups)
            color1: Theme.primary
            color2: Theme.accentSecondary
            color3: Theme.tertiary
            baseColor: Theme.surfaceBase
        }

        BlobInvertedRect {
            anchors.fill: parent
            group: blobGroup
            radius: Settings.screenCornerRadius
            borderTop: frameRoot.borderTop
            borderLeft: frameRoot.borderSide
            borderRight: frameRoot.borderSide
            borderBottom: frameRoot.borderBottom
        }

        BlobRect {
            group: blobGroup
            x: notifWrapper ? notifWrapper.x + blobMargin : 0
            y: notifWrapper ? notifWrapper.y + blobMargin : 0
            width: notifWrapper ? notifWrapper.width : 0
            height: notifWrapper ? notifWrapper.height : 0
            radius: Settings.screenCornerRadius
            deformScale: notifWrapper && notifWrapper.height > 0 ? 0.00001 : 0
            stiffness: 200
            damping: 60
            visible: notifWrapper ? notifWrapper.height > 0 : false
        }

        BlobRect {
            group: blobGroup
            // Extend into the left frame so the vertical pill merges (no gap)
            x: osdPanel ? osdPanel.visualX + blobMargin - Settings.screenBorderWidth : 0
            y: osdPanel ? osdPanel.visualY + blobMargin : 0
            width: osdPanel && osdPanel.pocketActive
                ? osdPanel.visualW + Settings.screenBorderWidth
                : 0
            height: osdPanel && osdPanel.pocketActive ? osdPanel.visualH : 0
            radius: osdPanel ? osdPanel.width / 2 : Settings.cardRadius
            deformScale: osdPanel && osdPanel.pocketActive ? 0.00001 : 0
            stiffness: 200
            damping: 60
            visible: osdPanel ? osdPanel.pocketActive : false
        }

        BlobRect {
            group: blobGroup
            x: launcherPanel ? launcherPanel.x + blobMargin : 0
            y: launcherPanel ? launcherPanel.y + blobMargin : 0
            width: launcherPanel && launcherPanel.visible ? launcherPanel.width : 0
            height: launcherPanel && launcherPanel.visible ? launcherPanel.height : 0
            radius: Settings.screenCornerRadius
            deformScale: launcherPanel && launcherPanel.visible ? 0.00001 : 0
            stiffness: 200
            damping: 60
            visible: launcherPanel ? launcherPanel.visible : false
        }

        BlobRect {
            group: blobGroup
            x: wallpaperPanel ? wallpaperPanel.x + blobMargin : 0
            y: wallpaperPanel ? wallpaperPanel.y + blobMargin : 0
            width: wallpaperPanel && wallpaperPanel.visible ? wallpaperPanel.width : 0
            height: wallpaperPanel && wallpaperPanel.visible ? wallpaperPanel.height : 0
            radius: Settings.screenCornerRadius
            deformScale: wallpaperPanel && wallpaperPanel.visible ? 0.00001 : 0
            stiffness: 200
            damping: 60
            visible: wallpaperPanel ? wallpaperPanel.visible : false
        }

        // Control center — flush with the right frame so the pocket merges (no gap)
        BlobRect {
            group: blobGroup
            x: controlCenterPanel ? controlCenterPanel.visualX + blobMargin : 0
            y: controlCenterPanel ? controlCenterPanel.visualY + blobMargin : 0
            width: controlCenterPanel && controlCenterPanel.pocketActive
                ? controlCenterPanel.visualW + Settings.screenBorderWidth
                : 0
            height: controlCenterPanel && controlCenterPanel.pocketActive ? controlCenterPanel.visualH : 0
            radius: Settings.screenCornerRadius
            deformScale: controlCenterPanel && controlCenterPanel.pocketActive ? 0.00001 : 0
            stiffness: 200
            damping: 60
            visible: controlCenterPanel ? controlCenterPanel.pocketActive : false
        }

        Repeater {
            model: PopupRegistry.pockets

            delegate: BlobRect {
                required property string pocketScreen
                required property real pocketX
                required property real pocketY
                required property real pocketW
                required property real pocketH
                required property real pocketRadius
                required property bool pocketVisible

                readonly property bool onThisScreen: {
                    if (pocketScreen !== frameRoot.screenName) return false
                    if (pocketW <= 0 || pocketH <= 0) return false
                    return true
                }

                x: pocketX + blobMargin
                y: pocketY + blobMargin
                width: onThisScreen ? pocketW : 0
                height: onThisScreen ? pocketH : 0
                radius: pocketRadius
                group: blobGroup
                visible: pocketVisible && onThisScreen
                stiffness: 200
                damping: 60
                deformScale: pocketVisible && onThisScreen ? 0.00001 : 0
            }
        }
    }
}
