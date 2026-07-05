pragma ComponentBehavior: Bound

import QtQuick
import qs.core
import qs.config
import qs.components.base

Item {
    id: root

    required property var notificationData
    property bool exiting: false
    property bool _isDestroying: false
    property bool _finalized: false

    readonly property bool hasValidData: notificationData && notificationData.summary

    signal entered
    signal exitFinished

    width: Settings.notificationWidth
    height: Settings.notificationHeight
    visible: hasValidData

    Behavior on y {
        enabled: !exiting && !_isDestroying
        NumberAnimation {
            duration: Settings.animationDurationMedium
            easing.type: Settings.easingStandard
        }
    }

    function startExit() {
        if (exiting || _isDestroying) return
        exiting = true
        exitAnim.restart()
        exitWatchdog.restart()
    }

    function forceExit() {
        if (_isDestroying) return
        _isDestroying = true
        exiting = true
        visible = false
        exitWatchdog.stop()
        finalizeExit("forced")
    }

    function finalizeExit(reason) {
        if (_finalized) return
        _finalized = true
        _isDestroying = true
        exitWatchdog.stop()
        root.exitFinished()
    }

    Timer {
        id: dismissTimer
        interval: notificationData && notificationData.timeout > 0 ? notificationData.timeout : Settings.notificationTimeout
        running: !exiting && !_isDestroying && hasValidData && !cardHoverArea.containsMouse && !flickable.moving
        onTriggered: root.startExit()
    }

    Timer {
        id: exitWatchdog
        interval: 600
        repeat: false
        onTriggered: finalizeExit("watchdog")
    }

    Flickable {
        id: flickable
        anchors.fill: parent
        visible: root.hasValidData

        contentWidth: width * 2
        contentHeight: height
        boundsBehavior: Flickable.DragOverBounds
        flickableDirection: Flickable.HorizontalFlick

        maximumFlickVelocity: Settings.flickMaxVelocity
        flickDeceleration: Settings.flickDeceleration

        leftMargin: 0
        rightMargin: 0
        onMovementEnded: {
            if (contentX > Settings.notificationDismissThreshold || contentX < -Settings.notificationDismissThreshold) {
                root.startExit()
            } else {
                snapBackAnim.restart()
            }
        }

        onContentXChanged: {
            if (contentX > 0) {
                popupCard.opacity = Math.max(0, 1 - (contentX / 300))
            } else if (contentX < 0) {
                popupCard.opacity = Math.max(0, 1 + (contentX / 300))
            } else {
                popupCard.opacity = 1
            }
        }

        Item {
            id: popupCard
            width: flickable.width
            height: flickable.height

            NotificationCard {
                anchors.fill: parent
                notification: root.notificationData
                onCloseRequested: {
                    if (!root.exiting)
                        root.startExit()
                }
                onActionInvoked: {
                    // NotificationService.activate() already removed this entry
                }
            }

            MouseArea {
                id: cardHoverArea
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.NoButton
                propagateComposedEvents: true
                z: -1
            }
        }
    }

    NumberAnimation {
        id: enterX
        target: flickable
        property: "contentX"
        from: -Settings.flickSlideDistance
        to: 0
        duration: Settings.animationDurationMedium
        easing.type: Settings.easingStandard
        running: false
    }

    ParallelAnimation {
        id: snapBackAnim

        PropertyAnimation {
            target: flickable
            property: "contentX"
            to: 0
            duration: Settings.animationDurationMedium
            easing.type: Settings.easingStandard
        }

        NumberAnimation {
            target: popupCard
            property: "opacity"
            to: 1
            duration: Settings.animationDurationMedium
            easing.type: Easing.OutQuad
        }
    }

    ParallelAnimation {
        id: exitAnim
        onStopped: finalizeExit("animStopped")

        PropertyAnimation {
            target: flickable
            property: "contentX"
            from: flickable.contentX
            to: flickable.contentX > 0 ? Settings.flickSlideDistance : -Settings.flickSlideDistance
            duration: Settings.animationDurationMedium
            easing.type: Settings.easingAccelerate
        }

        NumberAnimation {
            target: popupCard
            property: "opacity"
            from: popupCard.opacity
            to: 0
            duration: Settings.animationDurationMedium
            easing.type: Easing.InQuad
        }
    }

    Component.onCompleted: {
        if (hasValidData) {
            Qt.callLater(() => {
                enterX.restart()
                root.entered()
            })
        } else {
            forceExit()
        }
    }
}
