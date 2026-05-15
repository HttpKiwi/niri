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
            deformScale: 0.00001
            stiffness: 200
            damping: 60
        }

        BlobRect {
            group: blobGroup
            x: launcherPanel && launcherPanel.visible ? launcherPanel.x + blobMargin : 0
            y: launcherPanel && launcherPanel.visible ? launcherPanel.y + blobMargin : 0
            width: launcherPanel && launcherPanel.visible ? launcherPanel.width : 0
            height: launcherPanel && launcherPanel.visible ? launcherPanel.height : 0
            radius: Settings.screenCornerRadius
            deformScale: 0.00001
            stiffness: 200
            damping: 60
            visible: launcherPanel ? launcherPanel.visible : false
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
                deformScale: 0.00001
            }
        }
    }
}
