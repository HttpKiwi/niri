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
    property Item settingsPanel: null
    property Item calendarPanel: null
    readonly property real blobMargin: 50
    readonly property real borderTop: Settings.barHeight + blobMargin
    readonly property real borderSide: Settings.screenBorderWidth + blobMargin
    readonly property real borderBottom: Settings.screenBorderWidth + blobMargin
    readonly property real topReach: Math.min(Settings.barHeight - 4, 20)

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

        EdgeBlob { group: blobGroup; margin: frameRoot.blobMargin; panel: frameRoot.launcherPanel }
        EdgeBlob { group: blobGroup; margin: frameRoot.blobMargin; panel: frameRoot.wallpaperPanel }

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

        // Settings / calendar drop from the top: reach into the bar chrome so the SDF merges
        EdgeBlob {
            group: blobGroup
            margin: frameRoot.blobMargin
            reach: frameRoot.topReach
            panel: frameRoot.settingsPanel
            visible: frameRoot.settingsPanel ? frameRoot.settingsPanel.pocketActive : false
        }
        EdgeBlob {
            group: blobGroup
            margin: frameRoot.blobMargin
            reach: frameRoot.topReach
            panel: frameRoot.calendarPanel
            visible: frameRoot.calendarPanel ? frameRoot.calendarPanel.pocketActive : false
        }
    }
}
