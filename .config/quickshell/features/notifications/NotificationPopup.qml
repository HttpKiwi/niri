pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Widgets
import qs.core
import qs.config
import qs.components.base

/**
 * NotificationPopup - Individual notification popup window
 * Displays a single notification with animations and auto-dismiss
 */
PanelWindow {
    id: win
    
    // Required properties set by the manager
    required property var notificationData
    property int screenY: 0
    property bool exiting: false
    property bool _isDestroying: false
    property bool _finalized: false
    
    readonly property bool hasValidData: notificationData && notificationData.summary
    
    // Signals
    signal entered
    signal exitFinished
    
    // Window properties
    visible: hasValidData
    color: "transparent"
    implicitWidth: Settings.notificationWidth
    implicitHeight: Settings.notificationHeight
    exclusiveZone: -1
    
    // Position at top-right
    anchors {
        top: true
        right: true
    }
    
    margins {
        top: Settings.notificationTopMargin + screenY
        right: Settings.notificationRightMargin
    }
    
    // Mask to clip to rounded shape
    mask: Region {
        item: popupCard
    }
    
    // Functions
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
        win.exitFinished()
    }
    
    // Auto-dismiss timer
    Timer {
        id: dismissTimer
        interval: notificationData && notificationData.timeout > 0 ? notificationData.timeout : Settings.notificationTimeout
        running: !exiting && !_isDestroying && hasValidData && !cardHoverArea.containsMouse && !flickable.moving
        onTriggered: win.startExit()
    }
    
    // Watchdog timer
    Timer {
        id: exitWatchdog
        interval: 600
        repeat: false
        onTriggered: finalizeExit("watchdog")
    }
    
    // Flickable container for swipe-to-dismiss
    Flickable {
        id: flickable
        anchors.fill: parent
        visible: win.hasValidData
        
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
                win.startExit()
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
        
        // Main popup card
        Rectangle {
            id: popupCard
            width: flickable.width
            height: flickable.height
            color: Theme.surfaceBase
            radius: Settings.cardRadius

            border.width: Settings.cardBorderWidth
            border.color: Theme.cardBorder
            
            NotificationCard {
                anchors.fill: parent
                notification: win.notificationData
                onCloseRequested: {
                    if (!win.exiting)
                        win.startExit()
                }
            }
            
            // Hover area to pause timer
            MouseArea {
                id: cardHoverArea
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton
                propagateComposedEvents: true
                z: -1
                
                onClicked: {
                    if (!win.exiting && !flickable.moving)
                        win.startExit()
                }
            }
        }
    }
    
    // Enter animation
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
    
    // Snap back animation
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
    
    // Exit animation
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
    
    // Smooth Y position changes
    Behavior on screenY {
        enabled: !exiting && !_isDestroying
        NumberAnimation {
            duration: Settings.animationDurationMedium
            easing.type: Settings.easingStandard
        }
    }
    
    // Start enter animation on creation
    Component.onCompleted: {
        if (hasValidData) {
            Qt.callLater(() => {
                enterX.restart()
                win.entered()
            })
        } else {
            forceExit()
        }
    }
    
    Component.onDestruction: {
        _isDestroying = true
        exitWatchdog.stop()
    }
}
